<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">

  <profiles>
    <profile>
      <id>cicdRepos</id>
      <repositories>
        <repository>
          <id>maven-snapshots</id>
          <name>Maven snapshot repo</name>
          <url>NEXUS_URL/repository/maven-snapshots/</url>
          <releases>
            <enabled>false</enabled>
          </releases>
        </repository>
        <repository>
          <id>maven-releases</id>
          <name>Maven release repo</name>
          <url>NEXUS_URL/repository/maven-releases</url>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
        <repository>
          <id>maven-public</id>
          <name>Maven group repo</name>
          <url>NEXUS_URL/repository/maven-public/</url>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
      </repositories>

      <pluginRepositories>
        <pluginRepository>
          <id>maven-plugins</id>
          <name>Maven group repo</name>
          <url>NEXUS_URL/repository/maven-releases</url>
        </pluginRepository>
      </pluginRepositories>

    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>cicdRepos</activeProfile>
  </activeProfiles>

  <servers>
  <server>
    <id>maven-releases</id>
    <username>NEXUS_USER</username>
    <password>NEXUS_PASSWORD</password>
    <configuration>
      <httpConfiguration>
        <put>
            <params>
              <property>
                <name>http.protocol.expect-continue</name>
                <value>%b,false</value>
              </property>
            </params>
          </put>
       </httpConfiguration>
     </configuration>
  </server>
  <server>
    <id>maven-snapshots</id>
    <username>NEXUS_USER</username>
    <password>NEXUS_PASSWORD</password>
    <configuration>
      <httpConfiguration>
        <put>
            <params>
              <property>
                <name>http.protocol.expect-continue</name>
                <value>%b,false</value>
              </property>
            </params>
          </put>
       </httpConfiguration>
     </configuration>
  </server>
  </servers>

</settings>
