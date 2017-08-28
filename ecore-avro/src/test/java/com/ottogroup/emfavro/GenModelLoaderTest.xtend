package com.ottogroup.emfavro

import java.io.FileNotFoundException
import java.nio.file.Paths
import org.eclipse.emf.common.util.WrappedException
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat
import static org.assertj.core.api.Assertions.assertThatExceptionOfType

class GenModelLoaderTest {
    @Test
    def void shouldThrowNPEForNullParameter() {
        // when // then
        assertThatExceptionOfType(NullPointerException).isThrownBy[GenModelLoader::load(null)]
    }

    @Test
    def void shouldThrowIfFileIsNotExistent() {
        // given
        val path = Paths.get("nonexisting_path")

        // when // then
        assertThatExceptionOfType(FileNotFoundException)
            .isThrownBy[GenModelLoader::load(path)]
            .withMessageEndingWith("/nonexisting_path")
    }

    @Test
    def void shouldThrowIfGenModelIsInvalid() {
        // given
        val path = Paths.get(getClass.getResource("/invalid.genmodel").toURI)
        
        // when // then
        assertThatExceptionOfType(WrappedException)
            .isThrownBy[GenModelLoader::load(path)]
    }

    @Test
    def void shouldLoadEmptyGenModel() {
        // given
        val path = Paths.get(getClass.getResource("/empty.genmodel").toURI)

        // when
        val genModel = GenModelLoader::load(path)

        // then
        assertThat(genModel).isNotNull
        assertThat(genModel.modelName).isEqualTo("Test")
        assertThat(genModel.genPackages).isEmpty
    }

    @Test
    def void shouldThrowIfResourceContainsNoGenModel() {
        // given
        val path = Paths.get(getClass.getResource("/empty.ecore").toURI)

        // when // then
        assertThatExceptionOfType(RuntimeException)
            .isThrownBy[GenModelLoader::load(path)]
    }
    
    
    
}