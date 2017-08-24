package com.ottogroup.emfavro

import java.io.FileNotFoundException
import org.junit.Before
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat
import static org.assertj.core.api.Assertions.assertThatExceptionOfType

class GenModelLoaderTest {
    private var GenModelLoader loader

    @Before
    def void setUp() {
        loader = new GenModelLoader
    }

    @Test
    def void shouldThrowIfFileIsNotExistent() {
        // given
        val path = "nonexisting_path"

        // when // then
        assertThatExceptionOfType(FileNotFoundException)
            .isThrownBy[loader.load(path)]
    }

    @Test
    def void shouldLoadEmptyGenModel() {
        // given
        val path = getClass.getResource("/empty.genmodel").toURI.getPath

        // when
        val genModel = loader.load(path)

        // then
        assertThat(genModel).isNotNull
        assertThat(genModel.modelName).isEqualTo("Test")
        assertThat(genModel.genPackages).isEmpty
    }

    @Test
    def void shouldThrowIfResourceContainsNoGenModel() {
        // given
        val path = getClass.getResource("/empty.ecore").toURI.getPath

        // when // then
        assertThatExceptionOfType(IllegalArgumentException)
            .isThrownBy[loader.load(path)]
    }
    
    
    
}