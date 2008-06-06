
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#

require 'test/unit'
require 'openwfe/workitem'
require 'openwfe/util/dollar'


class WiTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_0

    wi = OpenWFE::InFlowWorkItem.new
    wi.attributes = {
      "field0" => "value0",
      "field1" => [ 0, 1, 2, 3, [ "a", "b", "c" ]],
      "field2" => {
        "a" => "AA",
        "b" => "BB",
        "c" => [ "C0", "C1", "C3" ]
      },
      "field3" => 3,
      "field99" => nil
    }

    assert_equal 3, wi.lookup_attribute("field3")
    assert_equal 1, wi.lookup_attribute("field1.1")
    assert_equal "b", wi.lookup_attribute("field1.4.1")
    assert_equal "C1", wi.lookup_attribute("field2.c.1")
    assert_equal nil, wi.lookup_attribute("field4")
    assert_equal nil, wi.lookup_attribute("field4.2")
    assert_equal nil, wi.lookup_attribute("field99")
    assert_equal nil, wi.lookup_attribute("field99.9")

    assert_equal false, wi.has_attribute?("field4")
    assert_equal false, wi.has_attribute?("field4.2")
    assert_equal true, wi.has_attribute?("field99")
    assert_equal false, wi.has_attribute?("field99.9")

    text = "value is '${f:field2.c.1}'"
    text = OpenWFE::dosub text, nil, wi
    assert_equal "value is 'C1'", text

    # setting attributes

    wi.set_attribute("field2.a", 42)
    wi.set_attribute("field99", "f99")

    assert_equal 42, wi.lookup_attribute("field2.a")
    assert_equal "f99", wi.lookup_attribute("field99")

    # unsetting attributes

    wi.unset_attribute "field99"
    assert_nil wi.lookup_attribute("field99")

    wi.unset_attribute "field1.4"
    assert_equal [ 0, 1, 2, 3 ], wi.lookup_attribute("field1")

    wi.unset_attribute "field2.c"
    assert_equal({ "a" => 42, "b" => "BB" }, wi.lookup_attribute("field2"))
  end

end

