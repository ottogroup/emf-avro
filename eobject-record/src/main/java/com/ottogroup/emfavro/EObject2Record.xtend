package com.ottogroup.emfavro

import java.util.Objects
import org.apache.avro.Protocol
import org.apache.avro.Schema
import org.apache.avro.generic.GenericData
import org.apache.avro.generic.GenericRecord
import org.apache.avro.generic.GenericRecordBuilder
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EEnumLiteral
import org.eclipse.emf.ecore.EObject

class EObject2Record {
    static def GenericRecord convert(EObject eObject, Protocol protocol) {
        Objects.requireNonNull(eObject, ["eObject is null"])
        Objects.requireNonNull(protocol, ["protocol is null"])

        val genericData = new GenericData()
        val schema = findAvroSchema(eObject.eClass, protocol)

        val builder = new GenericRecordBuilder(schema)
        eObject.eClass.EAllAttributes.forEach[
            if (it.EType instanceof EEnum) {
                val eEnum = it.EType as EEnum
                val literal = eObject.eGet(it) as EEnumLiteral
                val enumSchema = eEnum.findAvroSchema(protocol)
                val enumSymbol = genericData.createEnum(literal.name, enumSchema)
                builder.set(it.name, enumSymbol)
            } else {
                builder.set(it.name, eObject.eGet(it))
            }
        ]

        eObject.eClass.EAllReferences.forEach[
            val referencedRecord = convert(eObject.eGet(it) as EObject, protocol)
            builder.set(it.name, referencedRecord)
        ]

        builder.build
    }

    package static def Schema findAvroSchema(EClassifier eClass, Protocol protocol) {
        val builder = new StringBuilder
        if (!(protocol.namespace.isNullOrEmpty)) {
            builder.append(protocol.namespace)
            builder.append('.')
        }
        builder.append(eClass.EPackage.name)
        builder.append(".avro.")
        builder.append(eClass.name)

        val avroTypeName = builder.toString
        val schema = protocol.getType(avroTypeName)
        if (schema === null) throw new SchemaNotFoundException(protocol, avroTypeName)

        schema
    }
}