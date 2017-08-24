package com.ottogroup.emfavro

import java.io.ByteArrayInputStream
import org.apache.avro.Protocol
import org.apache.avro.compiler.idl.Idl
import org.eclipse.emf.codegen.ecore.genmodel.GenModel

class Ecore2Avro {
    static def Protocol convert(GenModel genModel) {
        val idlStr = new IDLGenerator().generateIdl(genModel)
        val input = new ByteArrayInputStream(idlStr.bytes)
        return new Idl(input).CompilationUnit
    }
}