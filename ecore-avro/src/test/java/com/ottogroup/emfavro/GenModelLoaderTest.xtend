package com.ottogroup.emfavro

import java.io.FileNotFoundException
import java.nio.file.Paths
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat
import static org.assertj.core.api.Assertions.assertThatExceptionOfType

class GenModelLoaderTest {
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