package com.ottogroup.emfavro

import java.io.File

import org.apache.maven.plugin.MojoFailureException
import org.apache.maven.plugin.testing.MojoRule
import org.apache.maven.project.MavenProject
import org.scalatest._

class Ecore2AvroMojoSpec extends FlatSpec with GivenWhenThen with Matchers with JUnitRules {
  private val unitdir = new File("src/test/resources/unit")

  "The Ecore2AvroMojo" should "create an output file" in withRule(new MojoRule) { rule =>
    Given("A correctly configured mojo")
    val basedir = new File(unitdir, "fine")
    val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
    mojo shouldNot be (null)

    When("The mojo is executed")
    mojo.execute()

    Then("The output file exist")
    val outputFile = new File("target/test-harness/base/Test.avpr")
    outputFile should exist
  }

  it should "throw a MojoFailureException for a nonexisting genmodel" in withRule(new MojoRule) { rule =>
    Given("A configured mojo pointing at a nonexisting genmodel file")
    val basedir = new File(unitdir, "nonexisting_genmodel")
    val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
    mojo shouldNot be (null)

    When("The mojo is executed")
    Then("A FileNotFoundException should be thrown")
    a [MojoFailureException] should be thrownBy mojo.execute()
  }

  it should "add a resource to the Maven project" in withRule(new MojoRule) { rule =>
    Given("A correctly configured mojo")
    val basedir = new File(unitdir, "fine")
    val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
    mojo shouldNot be (null)

    When("The mojo is executed")
    mojo.execute()

    Then("A resource should be added to the project")
    val project = rule.getVariableValueFromObject(mojo, "project").asInstanceOf[MavenProject]
    val expectedResourceDirectory = new File("target/test-harness").getAbsolutePath

    project.getResources should have size 1
    project.getResources.get(0).getDirectory shouldEqual expectedResourceDirectory
  }
}