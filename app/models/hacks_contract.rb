# frozen_string_literal: true

# Copyright (c) 2018, by Jiang Jinyang. <https://justjjy.com>
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

require 'ciri/utils'
# require "#{Rails.root}/vendor/console-3.3.1-all.jar"
# $CLASSPATH << "./contract"
#
# java_import org.web3j.protocol.core.methods.request.Transaction
# java_import org.web3j.crypto.Credentials
# java_import org.web3j.tx.Contract
# java_import org.web3j.tx.CitaTransactionManager
# java_import org.web3j.protocol.Web3j
# java_import org.web3j.protocol.http.HttpService
# java_import org.web3j.abi.datatypes.Function
# java_import org.web3j.abi.datatypes.Address
# java_import org.web3j.abi.TypeReference


module HacksContract
  URL = 'http://47.97.108.229:1337'.freeze

  BIN = 'cita-cli'

  class << self
    def web3j
      @web3j ||= Web3j.build(HttpService.new(URL))
    end

    def new_transaction_manager(priv_key, web3j: HacksContract.web3j)
      sender = Credentials.create(priv_key)
      CitaTransactionManager.new(web3j, sender)
    end

    def deploy_hackathon_contract(priv_key, gas_limit)
      transaction_manager = new_transaction_manager(priv_key)
      factory = new_hackathon_factory('0x71710b2330d2e882be0a72971e8e4cb8f20a55a6', transaction_manager, 1, gas_limit)
    end
  end

  class Hackathon
    include Ciri

    BINARY = "0x#{open("#{Rails.root}/contract/abi/Hackathon.bin").read}"
    ABI = "#{Rails.root}/contract/abi/Hackathon.abi"
    ABI_CONTENT = JSON.load open(ABI).read

    def initialize(address)
      @address = address
    end

    def votes(address)
      rpc('votes', [address[2..-1]])
    end

    def total_fund
      rpc('totalFound', [])
    end

    def sign_up_goal_reached
      rpc('signUpGoalReached', [])
    end

    def crowd_found_goal_reached
      rpc('crowdFoundGoalReached', [])
    end

    def closing_vote
      rpc('closingVote', [])
    end

    def closing_crowd_fund
      rpc('closingCrowdFound', [])
    end

    def champ
      rpc('champ', [])
    end

    def crowd_fund_period
      rpc('crowdFoundPeriod', [])
    end

    def champ_bonus
      rpc('champBonus', [])
    end

    def deposit
      rpc('deposit', [])
    end

    def closing_sign_up
      rpc('closingSignUp', [])
    end

    def remain_crowd_fund
      rpc('remainCrowdFound', [])
    end

    def crowd_fund_target
      rpc('crowdFoundTarget', [])
    end

    def second_bonus
      rpc('secondBonus', [])
    end

    def total_crowd_fund
      rpc('totalCrowdFound', [])
    end

    def closing_match
      rpc('closingMatch', [])
    end

    def sign_up_period
      rpc('signUpPeriod', [])
    end

    def sign_up_fee
      rpc('signUpFee', [])
    end

    def third_bonus
      rpc("thirdBonus", [])
    end

    def register_lower_limit
      rpc("registerLowerLimit", [])
    end

    def third
      rpc("third", [])
    end

    def vote_period
      rpc("votePeriod", [])
    end

    def init_fund
      rpc("initFound", [])
    end

    def match_period
      rpc('matchPeriod', [])
    end

    def state
      rpc('state', [])
    end

    def register_upper_limit
      rpc('registerUpperLimit', [])
    end

    def is_failed
      rpc('isFailed', [])
    end

    def rpc(function_name, args, invoke: true, transaction: false)
      # params = args.empty? ? "--param 1" : args.map {|arg| "--param #{arg}"}.join(" ")
      # command = [HacksContract::BIN, "ethabi", "encode", "function", params, ABI, function_name].join(" ")
      # p command
      # input = `#{command}`.strip[1..-2]
      input = encode_function(function_name, *args)
      if transaction
        command = [HacksContract::BIN, "rpc", "sendRawTransaction",
                   "--code", "0x#{input}",
                   "--address", @address,
                   "--quota", "100000000"].join(" ")
      else
        command = [
          HacksContract::BIN, "rpc", "call",
          "--data", "0x#{input}",
          "--to", @address,
        ].join(" ")
      end
      p command
      return command unless invoke
      transaction_res = `#{command}`
      transaction = JSON.load(transaction_res)
      return nil unless transaction
      Utils.big_endian_decode(Utils.hex_to_data(transaction["result"]))
      # get_receipt(transaction["result"]["hash"])
    end

    def encode_function(function_name, *args)
      HacksContract.encode_function(ABI_CONTENT, function_name, *args)
    end

    def get_receipt(h)
      p h, "cita-cli rpc getTransactionReceipt --hash #{h}"
      JSON.load `cita-cli rpc getTransactionReceipt --hash #{h}`
    end
  end

  class HackathonFactory
    include Ciri

    BINARY = "0x#{open("#{Rails.root}/contract/abi/HackathonFactory.bin").read}"
    ABI = "#{Rails.root}/contract/abi/HackathonFactory.abi"
    ADDRESS = "0x430ae2d2860a2aadd7acdb4fb3c1e7574964217c"
    ABI_CONTENT = JSON.load open(ABI).read

    # 10.to_wei,
    def create_hackathon(fund_target, fund_period, sign_up_period, match_period, vote_period, deposit, sign_up_fee, champ_bonus, second_bonus, thrid_bonus, vote_bonus, max_teams, min_teams, invoke: true)
      result = rpc('CreateHackathon', [fund_target, fund_period, sign_up_period, match_period, vote_period, deposit, sign_up_fee, champ_bonus, second_bonus, thrid_bonus, vote_bonus, max_teams, min_teams], invoke: invoke)
      return result unless invoke
      result["result"]["logs"][-1]["topics"][2][-20..-1]
    end

    def rpc(function_name, args, invoke: true)
      # command = [HacksContract::BIN, "ethabi", "encode", "function", args.map {|arg| "--param #{arg}"}.join(" "), ABI, function_name].join(" ")
      # p command
      # input = `#{command}`.strip[1..-2]
      input = encode_function(function_name, *args)
      command = [HacksContract::BIN, "rpc", "sendRawTransaction",
                 "--code", "0x#{input}",
                 "--address", ADDRESS,
                 "--quota", "100000000"]
      command += ["--private-key", "0x90522bd811a6794e07971de03e32e62c7a35fd677e6737a6146b18a8bcffc4df"] unless invoke
      command.join(" ")
      p command
      return command unless invoke
      transaction_res = `#{command}`
      transaction = JSON.load(transaction_res)
      get_receipt(transaction["result"]["hash"])
    end

    def encode_function(function_name, *args)
      HacksContract.encode_function(ABI_CONTENT, function_name, *args)
    end

    def get_receipt(h)
      `cita-cli rpc getTransactionReceipt --hash #{h}`
    end
  end

  def self.encode_function(abi, function_name, *args)
    abi2 = abi.find {|a| a['name'] == function_name}
    types = abi2['inputs'].map {|i|
      i['type']
    }
    signature = "#{function_name}(#{types.join ','})"
    first_byte = Ciri::Utils.sha3(signature)[0..3]
    encoded = first_byte + args.map {|i|
      if i.is_a?(Integer)
        Ciri::Utils.big_endian_encode_to_size(i, size: 32)
      else
        # asume is a address
        p Ciri::Utils.data_to_hex(Ciri::Utils.hex_to_data(i).rjust(32, "\x00".b))
        if i.size > 20
          Ciri::Utils.hex_to_data(i).rjust(32, "\x00".b)
        else
          i.rjust(32, "\x00".b)
        end
      end
    }.join
    p Ciri::Utils.data_to_hex(encoded)[2..-1]
    Ciri::Utils.data_to_hex(encoded)[2..-1]
  end

end
