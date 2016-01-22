#!/bin/bash

function buildAllProjects {
  LOG_FILE=$2
  JOB_FOLDER="JOB-"`date +%Y-%m-%d%H%M%S`
  mkdir $JOB_FOLDER
  cd $JOB_FOLDER

  echo  "------------------------------- JOB START $JOB_FOLDER ------------------------------- "
  filename="$1"
  while read -r line
  do
    name=$line
    echo  "------------------------------- START $line ------------------------------- "
    echo ""
    buildProject $line $JOB_FOLDER $LOG_FILE
    echo "-------------------------------- END $line --------------------------------- "
  done < "../$filename"

   echo -e "\n\n\n-------------------------------------- BUILD PROCESS COMPLETED --------------------------------------"
}


function buildProject {
    DATE=`date +%Y-%m-%d:%H:%M:%S`
    PROJECT_URL=$1
    JOB_FOLDER=$2
    LOG_FILE=$3
    JACOCO_GRADLE_TEMPLATE="/home/ubuntu/projects/BUILD_TEMPLATE/playground/jacoco.gradle"
    TEMPLATES_TEST="/home/ubuntu/projects/BUILD_TEMPLATE/playground/templates/test-template"
    OUT="/home/ubuntu/projects/BUILD_TEMPLATE/playground/log.txt"

    basename=$(basename $1)
    PROJECT_FOLDER=${basename%.*}
    
    echo  "$DATE cloning the repository for $PROJECT_FOLDER from $PROJECT_URL"
 
    GIT_URL=$PROJECT_URL".git";

    if git clone $GIT_URL $PROJECT_FOLDER >> "$LOG_FILE" 2>&1; then
        echo -e "[SUCCESS] Cloned the project successfully "
    else
        echo -e "[ERROR] Failed to clone the project"
        return -1;
    fi
    
    echo -e "[INFO] cd into project directory"
    cd $PROJECT_FOLDER

    find . -type f -name pom.xml 
    if [ -d "pom.xml" ]; then
       echo -e "[INFO] Its a maven based project"
       return 0;
    fi
    
    find . -mindepth 2 -type f -name build.gradle | sed -r 's|/[^/]+$||' |sort |uniq | while read file;
    do
      if [ -d "$file/src/test" ]; then
        echo -e "[SUCCESS] test folder exists under $file \n\n"
      else
        echo -e "[INFO] NO UNIT TEST under $file "
        echo -e "[INFO] Copuying the dummy tests in the $file"
        cp -r $TEMPLATES_TEST $file/src/
        if [ -d "$file/src/test" ]; then
           echo -e "[SUCCESS] copied the dummy tests under $file"
        else
           echo -e "[ERROR] Unable to copy the template dummy test under $file"
           return -1;
        fi
      fi
    done;
    
    
    if grep "android" build.gradle
    then
        JACOCO_GRADLE_TEMPLATE="/home/ubuntu/projects/BUILD_TEMPLATE/playground/jacoco_android.gradle"
        echo -e "[INFO] Its an android project \n\n"
    else
        JACOCO_GRADLE_TEMPLATE="/home/ubuntu/projects/BUILD_TEMPLATE/playground/jacoco.gradle"
        echo -e "[INFO] Its not an android project \n\n"
    fi
    
    echo -e "[INFO] Copying the jacoco.gradle to the project root \n\n"
    cp $JACOCO_GRADLE_TEMPLATE jacoco.gradle
    
    echo -e "[INFO] Appending the apply jacoco.gradle to every build.gradle file \n\n"
    find .  -mindepth 2 -name build.gradle -exec sh -c "echo >> {}; echo apply from: \'../jacoco.gradle\' >> {}" \;
    
    echo -e "[INFO] Here is the git diff that script has introduced \n\n"
    git diff
    
    echo -e "[INFO] Initiating the build \n\n"
    
    sudo chmod +x gradle 
    sudo chmod +x gradlew 

    if [ ! -f gradlew ]; then
        echo "[ERROR] gradlew file not found"
        return -1;
    fi

    ./gradlew cleanTest testDebugUnitTestCoverage  >> $LOG_FILE 2>&1
  
    echo -e "[INFO] Gradle Build completed \n\n"

    cd  ..
}

function extractRepoName {
 basename=$(basename $1)
 echo $basename
 filename=${basename%.*}
 return $filename
}

# Execution
buildAllProjects  repos.txt $1
