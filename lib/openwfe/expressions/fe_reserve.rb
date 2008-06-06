#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

#require 'thread'


module OpenWFE

  #
  # The 'reserve' expression ensures that its nested child expression
  # executes while a reserved mutex is set.
  #
  # Thus
  #
  #   concurrence do
  #     reserve :mutex => :m0 do
  #       sequence do
  #         participant :alpha
  #         participant :bravo
  #       end
  #     end
  #     reserve :mutex => :m0 do
  #       participant :charly
  #     end
  #     participant :delta
  #   end
  #
  # The sequence will not but run while the participant charly is active
  # and vice versa. The participant delta is not concerned.
  #
  # The mutex is a regular variable name, thus a mutex named "//toto" could
  # be used to prevent segments of totally different process instances from
  # running.
  #
  class ReserveExpression < FlowExpression

    #
    # A mutex for the whole class, it's meant to prevent 'reserve'
    # from reserving a workflow mutex simultaneaously.
    #
    #@@mutex = Mutex.new

    names :reserve

    #
    # The name of the mutex this expressions uses.
    # It's a variable name, that means it can be prefixed with
    # {nothing} (local scope), '/' (process scope) and '//' (engine /
    # global scope).
    #
    attr_accessor :mutex_name

    #
    # An instance variable for storing the applied workitem if the 'reserve'
    # cannot be entered immediately.
    #
    attr_accessor :applied_workitem


    def apply (workitem)

      return reply_to_parent(workitem) \
        if @children.size < 1

      @mutex_name = lookup_string_attribute :mutex, workitem

      #FlowMutex.synchronize do

      mutex = lookup_variable(@mutex_name) || FlowMutex.new(@mutex_name)

      mutex.register self, workitem
      #end
    end

    def reply (workitem)

      lookup_variable(@mutex_name).release self

      reply_to_parent workitem
    end

    #
    # Called by the FlowMutex to enter the 'reserved/critical' section.
    #
    def enter (workitem=nil)

      get_expression_pool.apply(
        @children[0], workitem || @applied_workitem)
    end
  end

  #
  # A FlowMutex is a process variable (thus serializable) that keeps
  # track of the expressions in a critical section (1!) or waiting for
  # entering it.
  #
  #--
  # The current syncrhonization scheme is 1 thread mutex for all the
  # FlowMutex. Shouldn't be too costly and the operations under sync are
  # quite tiny.
  #++
  #
  class FlowMutex

    #--
    # Granularity level ? "big rock". Only one FlowMutex operation
    # a a time for the whole business process engine...
    #
    #@@class_mutex = Mutex.new
    #++

    attr_accessor :mutex_name
    attr_accessor :feis

    def initialize (mutex_name)

      @mutex_name = mutex_name
      @feis = []
    end

    def register (fexp, workitem)

      @feis << fexp.fei

      fexp.set_variable @mutex_name, self

      if @feis.size == 1
        #
        # immediately let the expression enter the critical section
        #
        fexp.store_itself
        fexp.enter workitem
      else
        #
        # later...
        #
        fexp.applied_workitem = workitem
        fexp.store_itself
      end
    end

    def release (releaser)

      next_fei = nil

      #@@class_mutex.synchronize do

      current_fei = @feis.delete_at 0

      releaser.set_variable @mutex_name, self

      log.warn "release() BAD! c:#{current_fei} r:#{releaser.fei}" \
        if releaser.fei != current_fei

      next_fei = @feis.first
      #end

      return unless next_fei

      releaser.get_expression_pool.fetch_expression(next_fei).enter
    end

    #--
    # Used by the ReserveExpression when looking up for a FlowMutex
    # and registering into it.
    #
    #def self.synchronize (&block)
    #  @@class_mutex.synchronize do
    #    block.call
    #  end
    #end
    #++
  end

end

