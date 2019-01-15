#!/usr/bin/env bash

#if [[ "$1" -eq "" ]]; then
#	echo "provide windchill home location";
#	exit 1;
#elif [[ "$2" -eq "" ]]; then
#	echo "provide repository directory";
#	exit 2;
#elif [[ "$3" -eq "" ]]; then
#	echo "provide windchill version";
#	exit 3;
#fi;

wt_home_dir="$1";	#windchill home
repodir="$2";	#dir to generate repository files
codebase="$wt_home_dir/codebase/";
version="$3"		#windchill version, will be used for jars
group_id="com.ptc";
packaging="jar";
genpom="true";
chksum="true";
scope="provided";

pushd . ;

cd $codebase;

echo "[INFO]: Copying required files";

for i in $(find . -type f -name "*.class"); do
	class_path=$(dirname $i);
	echo "[INFO] Processing classfile: $i";
	mkdir -p "$repodir/codebase/$class_path";
	cp "$i"  "$repodir/codebase/$class_path";
done;

for i in $(find . -type f -name "*.ser"); do
	class_path=$(dirname $i);
	echo "[INFO] Processing ser file: $i";
	mkdir -p "$repodir/codebase/$class_path";
	cp "$i"  "$repodir/codebase/$class_path";
done;
echo "[INFO] Done copying";

echo "[INFO] Making jar";

cd "$repodir/codebase/" ;

zip ../codebase.jar -r ./* ;

#rm -rf "$repodir/codebase/"; # cleanup unwanted files, commented out intentionally, uncomment if know what you're doing...

echo "[INFO] Jar created";

mkdir -p "$repodir/jars/srclib"
mkdir -p "$repodir/jars/lib"
mkdir -p "$repodir/jars/webinf"

echo "[INFO] Copying jars from directory [srclib]"
for i in $(find "$wt_home_dir/srclib/tool" -type f -name "*.jar"); do
	cp "$i" "$repodir/jars/srclib/";
done;
echo "[INFO] Done copying jars"


echo "[INFO] Copying jars from directory [lib]"
for i in $(find "$wt_home_dir/lib" -type f -name "*.jar"); do
	cp "$i" "$repodir/jars/lib/";
done;
echo "[INFO] Done copying jars"

echo "[INFO] Copying jars from directory [webinf]"
for i in $(find "$wt_home_dir/codebase/WEB-INF" -type f -name "*.jar"); do
	cp "$i" "$repodir/jars/webinf/";
done;
echo "[INFO] Done copying jars"

echo "[INFO] Generating xml and command files";

mvn_inst_file="$repodir/mvn.cmd" ;
touch $mvn_inst_file ;

mvn_dep_pom="$mvn_inst_file.xml";
touch $mvn_dep_pom ;

echo "<dependencies>" >> $mvn_dep_pom ;
for i in $(find $repodir -type f -name "*.jar"); do
	filename="$(basename $i | sed  's/\.jar$//g')";
	mvn_inst_cmd="mvn install:install-file -Dfile=$i -DgroupId=$group_id -DartifactId=$filename -Dversion=$version -Dpackaging=$packaging -DgeneratePom=$genpom -DcreateChecksum=$chksum";

	echo "$mvn_inst_cmd" >> $mvn_inst_file ;

	echo "	<dependency>" >> $mvn_dep_pom ;
	echo "		<groupId>$group_id</groupId>" >> $mvn_dep_pom ;
	echo "		<artifactId>$filename</artifactId>" >> $mvn_dep_pom ;
	echo "		<version>$version</version>" >> $mvn_dep_pom ;
	echo "		<scope>$scope</scope>" >> $mvn_dep_pom ;
	echo "	</dependency>" >> $mvn_dep_pom ;
done;
echo "</dependencies>" >> $mvn_dep_pom ;
echo "[INFO] Done creating files."
popd;

echo -e "[MSG]: Run \"$mvn_inst_file\" to install all the windchill dependencies..\nTo include dependency in pom.xml use \"$mvn_dep_pom\" file to copy and paste..";
echo -e "After running the \"$mvn_inst_file\", all jars will be included in configured mvn local repo location(default: <userhome>/.m2/repository). You can copy the com.ptc folder to push into any other global repo like git or nexus or any other.\n\nYou can Delete $repodir once done installing \"$mvn_inst_file\"";

