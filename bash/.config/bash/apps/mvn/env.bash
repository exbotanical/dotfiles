init::export M2_HOME /usr/local/apache-maven/apache-maven-3.8.6
init::export M2 $M2_HOME/bin
init::export MAVEN_OPTS '-Xms256m -Xmx512m'

init::append_path $M2
