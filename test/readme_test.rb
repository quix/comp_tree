require File.dirname(__FILE__) + "/common"

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../devel"
require "jumpstart"

Jumpstart.doc_to_test("README.rdoc", "Synopsis")
