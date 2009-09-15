#--
# Copyright (c) 2005-2009, Alain Hoang and John Mettraux.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'net/smtp'

require 'ruote/engine/context'
require 'ruote/part/local_participant'
require 'ruote/part/template'


module Ruote

  #
  # A very stupid SMTP participant, doesn't even care about formatting its
  # messages. This class is meant as a base for more complex email participants.
  #
  # == options
  #
  # * :server - the IP address or hostname of the SMTP server/gateway (defaults to '127.0.0.1')
  # * :port - the port of the SMTP server/gateway (defaults to 25)
  # * :from - the from mail address (mandatory)
  # * :to - the to mail address[es]
  # * :template - a String template for the mail message
  # * :notification - when set to true, the flow will resume immediately after having sent the email
  #
  # == :template
  #
  #   @engine.register_participant(
  #     :no_good_notification
  #     Ruote::SmtpParticipant,
  #     :server => 'smtp.example.com'
  #     :port => 25,
  #     :to => 'toto@example.com',
  #     :from => 'john@example.com',
  #     :notification => true,
  #     :template => "Subject: ${f:email_subject}\n\nno good.")
  #
  # Process variable / workitem field substitution works the same as in
  # process definitions (in this example, the workitem field email_subject will
  # be used as the subject of the email...)
  #
  # == block template
  #
  # Whereas the :template option accepts a String, the block template may
  # be useful when more complex templates are to be computed.
  #
  #   @engine.register_participant(
  #     :no_good_notification
  #     Ruote::SmtpParticipant,
  #     :server => 'smtp.example.com'
  #     :port => 25,
  #     :to => 'toto@example.com',
  #     :from => 'john@example.com',
  #     :notification => true
  #   ) do
  #
  #     s = []
  #     s << "From: the boss"
  #     s << "Date: ${r:Time.now.rfc2822}"
  #     s << "Subject: ${f:email_subject}\n"
  #     s << ""
  #     3.times { s << "this is no good." }
  #
  #     s.join("\n")
  #   end
  #
  #
  # == mail listener
  #
  # This participant cannot read POP/IMAP accounts for you. You have to
  # use a mail listener or get a web reply by placing a link in the message...
  #
  class SmtpParticipant

    include EngineContext
    include LocalParticipant
    include TemplateMixin

    def initialize (opts, &block)

      @server = opts[:server] || '127.0.0.1'
      @port = opts[:port] || 25

      @from = opts[:from]
      @to = opts[:to]

      @template = opts[:template]
      @block_template = block

      @notification = opts[:notification]
    end

    def consume (workitem)

      to = workitem.fields['email_target'] || @to
      to = Array(to)

      text = render_template(expstorage[workitem.fei], workitem)

      Net::SMTP.start(@server, @port) do |smtp|
        smtp.send_message(text, @from, *to)
      end

      reply_to_engine(workitem) if @notification
    end

    def cancel (fei, flavour)

      # does nothing
    end
  end
end
