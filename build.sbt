organization := "org.links"

name := "objecthash"

version := "1.0-SNAPSHOT"

autoScalaLibrary := false

crossPaths := false

outputStrategy := Some(StdoutOutput)

mainClass in (Compile, run) := Some ("org.links.objecthash.ObjectHashTest")

libraryDependencies ++= Seq(
  "org.json" % "json" % "20090211",
  "junit" % "junit" % "4.10" % "test",
  "com.novocode" % "junit-interface" % "0.8" % "test->default"
)
