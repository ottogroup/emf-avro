package com.ottogroup.emfavro

import org.apache.avro.Protocol

class SchemaNotFoundException(protocol: Protocol, schemaName: String)
  extends RuntimeException(s"Cannot find a type named $schemaName in the protocol ${protocol.getNamespace}.${protocol.getName}") {}
