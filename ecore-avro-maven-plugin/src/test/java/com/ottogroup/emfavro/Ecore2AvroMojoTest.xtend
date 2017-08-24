package com.ottogroup.emfavro

import java.io.File
import org.apache.maven.plugin.testing.MojoRule
import org.junit.Rule
import org.junit.Test

import static org.assertj.core.api.Assertions.*
import java.io.FileNotFoundException
import org.apache.maven.project.MavenProject
import org.apache.maven.model.Resource

class Ecore2AvroMojoTest {
    private val unitdir = new File("src/test/resources/unit")

    @Rule
    public val rule = new MojoRule

    @Test
    def void shouldCreateOutputFile() {
        // given
        val basedir = new File(unitdir, "fine")
        val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
        assertThat(mojo).isNotNull

        // when
        mojo.execute

        // then
        val outputFile = new File("target/test-harness/Test.avpr")
        assertThat(outputFile).exists.isFile
    }

    @Test
    def void shouldThrowForNonexistingGenmodel() {
        // given
        val basedir = new File(unitdir, "nonexisting_genmodel")
        val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
        assertThat(mojo).isNotNull

        // when // then
        assertThatExceptionOfType(FileNotFoundException).isThrownBy[mojo.execute]
    }

    @Test
    def void shouldAddResourceToProject() {
        // given
        val basedir = new File(unitdir, "fine")
        val mojo = rule.lookupMojo("generate", new File(basedir, "pom.xml"))
        assertThat(mojo).isNotNull

        // when
        mojo.execute

        // then
        val project = rule.getVariableValueFromObject(mojo, "project") as MavenProject
        val resource = new Resource
        resource.directory = new File("target/test-harness").absolutePath
        assertThat(project.resources).hasSize(1)
        assertThat(project.resources.head.directory).isEqualTo(resource.directory)
    }
}