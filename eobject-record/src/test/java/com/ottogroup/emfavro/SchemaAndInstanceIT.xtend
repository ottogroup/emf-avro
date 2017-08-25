package com.ottogroup.emfavro

import java.nio.file.Paths
import org.apache.avro.generic.GenericData
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat

class SchemaAndInstanceIT {
    @Test
    def void shouldConvertXMIPrimitivesToAvroCorrectly() {
        // given
        val genModelPath = Paths.get(getClass.getResource("/test.genmodel").toURI)
        val genModel = new GenModelLoader().load(genModelPath)
        val testPackage = genModel.genPackages.head.getEcorePackage
        EPackage.Registry.INSTANCE.put(testPackage.nsURI, testPackage)

        val resourceSet = new ResourceSetImpl
        val extensionMap = resourceSet.resourceFactoryRegistry.extensionToFactoryMap
        extensionMap.put("test", new XMIResourceFactoryImpl)

        val uri = URI.createURI(getClass.getResource("/primitives.test").toString)
        val resource = resourceSet.getResource(uri, true)
        val primitives = resource.contents.head

        // when
        val protocol = Ecore2Avro.convert(genModel)
        val record = EObject2Record.convert(primitives, protocol)
        
        // then
        assertThat(record).isNotNull
        assertThat(record.get("booleanAttr")).isEqualTo(true)
        assertThat(record.get("intAttr")).isEqualTo(42)
        assertThat(record.get("longAttr")).isEqualTo(1337L)
        assertThat(record.get("floatAttr")).isEqualTo(3.14f)
        assertThat(record.get("doubleAttr")).isEqualTo(123.456789)
        assertThat(record.get("stringAttr")).isEqualTo("foo")
        assertThat(record.get("weekDay")).isInstanceOf(GenericData.EnumSymbol)
        assertThat(record.get("weekDay").toString).isEqualTo("FRIDAY")
    }
}