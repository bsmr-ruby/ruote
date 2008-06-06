
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/extras/participants/csvparticipants'

include OpenWFE
include OpenWFE::Extras



class FlowTest19 < Test::Unit::TestCase
  include FlowTestBase

  CSV0 = \
"""
in:weather, in:month, out:take_umbrella?
,,
raining,  ,     yes
sunny,    ,     no
cloudy,   june,   yes
cloudy,   may,    yes
cloudy,   ,     no
"""

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class TestDefinition0 < ProcessDefinition
    sequence do
      set :field => "weather", :value => "cloudy"
      set :field => "month", :value => "may"
      decision
      _print "${f:take_umbrella?}"
    end
  end

  def test_0

    csvParticipant = CsvParticipant.new(CSV0)

    @engine.register_participant("decision", csvParticipant)

    dotest(
      TestDefinition0,
      "yes")
  end

end

