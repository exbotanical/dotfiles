# Arch links the default JDK to /usr/lib/jvm/default; Ubuntu names the directory by version.
for jdk in /usr/lib/jvm/default /usr/lib/jvm/java-17-openjdk-amd64; do
  [[ -d $jdk ]] && init::export JAVA_HOME $jdk && break
done
init::append_path $JAVA_HOME
