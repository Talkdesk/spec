require File.dirname(__FILE__) + '/../../../spec_helper'
require 'net/ftp'
require File.dirname(__FILE__) + "/fixtures/server"

describe "Net::FTP#login" do
  before(:each) do
    @server = NetFTPSpecs::DummyFTP.new
    @server.serve_once

    @ftp = Net::FTP.new
    @ftp.connect("localhost", 9921)
  end

  after(:each) do
    @ftp.quit rescue nil
    @ftp.close
    @server.stop
  end

  describe "when passed no arguments" do
    it "sends the USER command with 'anonymous' as name to the server" do
      @ftp.login
      @ftp.last_response.should == "230 User logged in, proceed. (USER anonymous)\n"
    end
    
    it "sends the current username + hostname as a password when required" do
      pass = ENV["USER"] + "@" + Socket.gethostname
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
      @ftp.login
      @ftp.last_response.should == "230 User logged in, proceed. (PASS #{pass})\n"
    end
    
    ruby_bug "", "1.8.7" do
      # I have no idea how this should work. It currently raises an error.
      it "should description" do
        @server.should_receive(:user).and_respond("331 User name okay, need password.")
        @server.should_receive(:pass).and_respond("332 Need account for login.")
        @ftp.login
        @ftp.last_response.should == ""
      end
    end
  end
  
  describe "when passed name" do
    it "sends the USER command with the passed name to the server" do
      @ftp.login("rubyspec")
      @ftp.last_response.should == "230 User logged in, proceed. (USER rubyspec)\n"
    end
    
    # TODO: No idea how this hsould work. Raises an error.
    ruby_bug "", "1.8.7" do
      it "should description" do
        @server.should_receive(:user).and_respond("331 User name okay, need password.")
        @ftp.login("rubyspec")
        @ftp.last_response.should == ""
      end

      # I have no idea how this should work. It currently raises an error.
      it "should description" do
        @server.should_receive(:user).and_respond("331 User name okay, need password.")
        @server.should_receive(:pass).and_respond("332 Need account for login.")
        @ftp.login("rubyspec")
        @ftp.last_response.should == ""
      end
    end
  end
  
  describe "when passed name, password" do
    it "sends the USER command with the passed name to the server" do
      @ftp.login("rubyspec", "rocks")
      @ftp.last_response.should == "230 User logged in, proceed. (USER rubyspec)\n"
    end
    
    it "sends the passed password when required" do
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
      @ftp.login("rubyspec", "rocks")
      @ftp.last_response.should == "230 User logged in, proceed. (PASS rocks)\n"
    end
    
    ruby_bug "", "1.8.7" do
      # I have no idea how this should work. It currently raises an error.
      it "should description" do
        @server.should_receive(:user).and_respond("331 User name okay, need password.")
        @server.should_receive(:pass).and_respond("332 Need account for login.")
        @ftp.login("rubyspec", "rocks")
        @ftp.last_response.should == ""
      end
    end
  end
  
  describe "when passed name, password, account" do
    it "sends the USER command with the passed name to the server" do
      @ftp.login("rubyspec", "rocks", "account")
      @ftp.last_response.should == "230 User logged in, proceed. (USER rubyspec)\n"
    end
    
    it "sends the passed password when required" do
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
      @ftp.login("rubyspec", "rocks", "account")
      @ftp.last_response.should == "230 User logged in, proceed. (PASS rocks)\n"
    end
    
    it "sends the passed account when required" do
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
      @server.should_receive(:pass).and_respond("332 Need account for login.")
      @ftp.login("rubyspec", "rocks", "account")
      @ftp.last_response.should == "230 User 'account' logged in, proceed. (ACCT)\n"
    end
  end
  
  describe "when the USER command fails" do
    it "raises a Net::FTPPermError when the response code is 500" do
      @server.should_receive(:user).and_respond("500 Syntax error, command unrecognized.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
    
    it "raises a Net::FTPPermError when the response code is 501" do
      @server.should_receive(:user).and_respond("501 Syntax error in parameters or arguments.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPPermError when the response code is 502" do
      @server.should_receive(:user).and_respond("502 Command not implemented.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPTempError when the response code is 421" do
      @server.should_receive(:user).and_respond("421 Service not available, closing control connection.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPTempError)
    end

    it "raises a Net::FTPPermError when the response code is 530" do
      @server.should_receive(:user).and_respond("530 Not logged in.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
  end
  
  describe "when the PASS command fails" do
    before(:each) do
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
    end
    
    it "does not raise an Error when the response code is 202" do
      @server.should_receive(:pass).and_respond("202 Command not implemented, superfluous at this site.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should_not raise_error
    end
    
    it "raises a Net::FTPPermError when the response code is 500" do
      @server.should_receive(:pass).and_respond("500 Syntax error, command unrecognized.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
    
    it "raises a Net::FTPPermError when the response code is 501" do
      @server.should_receive(:pass).and_respond("501 Syntax error in parameters or arguments.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPPermError when the response code is 502" do
      @server.should_receive(:pass).and_respond("502 Command not implemented.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPTempError when the response code is 421" do
      @server.should_receive(:pass).and_respond("421 Service not available, closing control connection.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPTempError)
    end

    it "raises a Net::FTPPermError when the response code is 530" do
      @server.should_receive(:pass).and_respond("530 Not logged in.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
  end
  
  describe "when the ACCT command fails" do
    before(:each) do
      @server.should_receive(:user).and_respond("331 User name okay, need password.")
      @server.should_receive(:pass).and_respond("332 Need account for login.")
    end
    
    it "does not raise an Error when the response code is 202" do
      @server.should_receive(:acct).and_respond("202 Command not implemented, superfluous at this site.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should_not raise_error
    end
    
    it "raises a Net::FTPPermError when the response code is 500" do
      @server.should_receive(:acct).and_respond("500 Syntax error, command unrecognized.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
    
    it "raises a Net::FTPPermError when the response code is 501" do
      @server.should_receive(:acct).and_respond("501 Syntax error in parameters or arguments.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPPermError when the response code is 502" do
      @server.should_receive(:acct).and_respond("502 Command not implemented.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end

    it "raises a Net::FTPTempError when the response code is 421" do
      @server.should_receive(:acct).and_respond("421 Service not available, closing control connection.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPTempError)
    end

    it "raises a Net::FTPPermError when the response code is 530" do
      @server.should_receive(:acct).and_respond("530 Not logged in.")
      lambda { @ftp.login("rubyspec", "rocks", "account") }.should raise_error(Net::FTPPermError)
    end
  end
end