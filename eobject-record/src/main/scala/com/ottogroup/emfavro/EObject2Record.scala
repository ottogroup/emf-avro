package com.ottogroup.emfavro

import org.apache.avro.{Protocol, Schema}
import org.apache.avro.generic.{GenericData, GenericRecord, GenericRecordBuilder}
import org.eclipse.emf.ecore._

object EObject2Record {

  def findAvroSchema(classifier: EClassifier, protocol: Protocol): Schema = {
    val builder = new StringBuilder
    if (!(protocol.getNamespace == null || protocol.getNamespace.isEmpty)) {
      builder.append(protocol.getNamespace)
      builder.append('.')
    }

    builder.append(classifier.getEPackage.getName)
    builder.append(".avro.")
    builder.append(classifier.getName)

    val avroTypeName = builder.toString
    Option(protocol.getType(avroTypeName)) match {
      case Some(s) => s
      case None => throw new SchemaNotFoundException(protocol, avroTypeName)
    }
  }

  def convert(eObject: EObject, protocol: Protocol): GenericRecord = {
    require(eObject != null, "eObject must not be null")
    require(protocol != null, "protocol must not be null")

    val genericData = new GenericData
    val schema = findAvroSchema(eObject.eClass(), protocol)
    val builder = new GenericRecordBuilder(schema)

    eObject.eClass.getEAllAttributes.forEach { attr =>
      attr.getEAttributeType match {
        case eEnum: EEnum =>
          val literal = eObject.eGet(attr).asInstanceOf[EEnumLiteral]
          val enumSchema = findAvroSchema(eEnum, protocol)
          val symbol = genericData.createEnum(literal.getName, enumSchema)
          builder.set(attr.getName, symbol)
        case EcorePackage.Literals.EBOOLEAN | EcorePackage.Literals.EINT |
          EcorePackage.Literals.ELONG | EcorePackage.Literals.EFLOAT |
          EcorePackage.Literals.EDOUBLE => builder.set(attr.getName, eObject.eGet(attr))
        case _ => builder.set(attr.getName, eObject.eGet(attr).toString)
      }
    }

    eObject.eClass.getEAllReferences.forEach { ref =>
      val referencedRecord = convert(eObject.eGet(ref).asInstanceOf[EObject], protocol)
      builder.set(ref.getName, referencedRecord)
    }

    builder.build()
  }
}
