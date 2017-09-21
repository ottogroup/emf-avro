package com.ottogroup.emfavro

import org.apache.avro.{Protocol, Schema}
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.ecore._

import scala.collection.JavaConverters._

object Ecore2Avro {
  def convert(genModel: GenModel): Protocol = {
    require(genModel != null, "genModel must not be null")
    require(!genModel.getGenPackages.isEmpty, "genModel must contains at least 1 GenPackage")

    val protocol = new Protocol(genModel.getModelName, genModel.getGenPackages.get(0).getBasePackage)
    val schemas = genModel.getGenPackages.asScala
      .map(pkg => pkg -> pkg.getEcorePackage.getEClassifiers.asScala.filter(shouldBeConverted))
      .flatMap{ case (pkg, classifiers) =>
        classifiers.map(toAvroSchema(_, pkg.getBasePackage, genModel))
      }

    protocol.setTypes(schemas.asJava)
    protocol
  }

  def shouldBeConverted(eClassifier: EClassifier): Boolean = eClassifier match {
    case eClass: EClass => !eClass.isAbstract
    case _: EEnum => true
    case _: EDataType => false
  }

  def toAvroSchema(classifier: EClassifier, basePackage: String, model: GenModel): Schema = classifier match {
    case e: EEnum => toAvroSchema(e, basePackage, model)
    case c: EClass => toAvroSchema(c, basePackage, model)
    case dt: EDataType => toAvroSchema(dt, basePackage, model)
  }

  def toAvroSchema(enum: EEnum, basePackage: String, genModel: GenModel): Schema = Schema.createEnum(
    enum.getName, null, s"$basePackage.${enum.getEPackage.getName}.avro",
    enum.getELiterals.asScala.map(_.getName).asJava
  )

  def toAvroSchema(eClass: EClass, basePackage: String, genModel: GenModel): Schema = Schema.createRecord(
    eClass.getName, null, s"$basePackage.${eClass.getEPackage.getName}.avro", false,
    eClass.getEAllStructuralFeatures.asScala.map(toAvroField(_, basePackage, genModel)).asJava
  )

  def toAvroSchema(dataType: EDataType, basePackage: String, genModel: GenModel): Schema = dataType match {
    case EcorePackage.Literals.EBOOLEAN => Schema.create(Schema.Type.BOOLEAN)
    case EcorePackage.Literals.EINT => Schema.create(Schema.Type.INT)
    case EcorePackage.Literals.ELONG => Schema.create(Schema.Type.LONG)
    case EcorePackage.Literals.EFLOAT => Schema.create(Schema.Type.FLOAT)
    case EcorePackage.Literals.EDOUBLE => Schema.create(Schema.Type.DOUBLE)
    case _ => Schema.create(Schema.Type.STRING)
  }

  def toAvroField(feature: EStructuralFeature, basePackage: String, genModel: GenModel): Schema.Field = feature match {
    case attr: EAttribute => toAvroField(attr, basePackage, genModel)
    case ref: EReference => toAvroField(ref, basePackage, genModel)
  }

  def toAvroField(attr: EAttribute, basePackage: String, genModel: GenModel): Schema.Field = {
    var schema = attr.getEAttributeType match {
      case e: EEnum => toAvroSchema(e, basePackage, genModel)
      case dt: EDataType => toAvroSchema(dt, basePackage, genModel)
    }
    if (attr.getUpperBound == -1 || attr.getUpperBound > 1) {
      schema = Schema.createArray(schema)
    }

    new Schema.Field(attr.getName, schema, null, null.asInstanceOf[Object])
  }

  def toAvroField(ref: EReference, basePackage: String, genModel: GenModel): Schema.Field = {
    val `type` = ref.getEReferenceType
    var schema: Schema = if (`type`.isInterface) {
      Schema.createUnion(findImplementations(`type`, genModel)
        .map(toAvroSchema(_, basePackage, genModel)).toList.asJava)
    } else {
      toAvroSchema(`type`, basePackage, genModel)
    }

    if (ref.getUpperBound == -1 || ref.getUpperBound > 1) {
      schema = Schema.createArray(schema)
    }

    new Schema.Field(ref.getName, schema, null, null.asInstanceOf[Object])
  }

  def findImplementations(interface: EClass, genModel: GenModel): Iterable[EClassifier] =
    genModel.getGenPackages.asScala
      .flatMap(_.getEcorePackage.getEClassifiers.asScala)
      .filter(_.isInstanceOf[EClass])
      .filter(_ implements interface)

  implicit class RichEClassifier(val eClassifier: EClassifier) extends AnyRef {
    def implements(interface: EClass): Boolean = eClassifier match {
      case eClass: EClass => !eClass.isAbstract && !eClass.isInterface && interface.isSuperTypeOf(eClass)
      case _ => false
    }
  }
}
