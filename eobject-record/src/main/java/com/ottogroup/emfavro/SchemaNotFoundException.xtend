package com.ottogroup.emfavro

import org.apache.avro.Protocol

class SchemaNotFoundException extends RuntimeException {
    new(Protocol protocol, String schemaName) {
        super('''Cannot find a type named «schemaName» in the protocol «protocol.namespace».«protocol.name»''')
    }

    new(String message) {
        super(message)
    }
}