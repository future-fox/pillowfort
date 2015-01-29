require 'rails_helper'

# ------------------------------------------------------------------------------
# Shared Examples
# ------------------------------------------------------------------------------

RSpec.shared_examples 'an auth token resetter' do
  describe 'its affect on the auth_token' do
    subject { account.auth_token }

    describe 'before the call' do
      it { should eq(auth_token) }
    end

    describe 'after the call' do
      before { call_the_method }
      it { should_not eq(auth_token) }
    end
  end

  describe 'its affect on the auth_token_expires_at' do
    subject { account.auth_token_expires_at }

    describe 'before the call' do
      it { should eq(auth_token_expires_at) }
    end

    describe 'after the call' do
      before { call_the_method }
      it { should be > auth_token_expires_at }
    end
  end
end

# ------------------------------------------------------------------------------
# The Spec!
# ------------------------------------------------------------------------------

RSpec.describe Account, :type => :model do

  describe 'its validations' do
    before { account.save }
    subject { account.errors.messages }

    describe 'email validations' do
      let(:account) { FactoryGirl.build(:account, email: email) }

      context 'presence_of' do
        let(:email) { nil }

        it { should include(email: ["can't be blank"]) }
      end

      context 'uniqueness' do
        let(:email) { 'foobar@baz.com' }
        let(:dup_account) { FactoryGirl.build(:account, email: email) }
        before  { dup_account.save }
        subject { dup_account.errors.messages}

        it { should include(email: ["has already been taken"]) }
      end
    end

    describe 'password validations' do
      let(:account) { FactoryGirl.build(:account, password: password) }

      context 'presence_of' do
        let(:password) { nil }

        it { should include(password: [/can't be blank/, /is too short/]) }
      end

      context 'length of' do
        context "when it's too short" do
          let(:password) { "x"*3 }

          it { should include(password: [/is too short/])}
        end

        context "when it's too long" do
          let(:password) { "x"*80 }

          it { should include(password: [/is too long/])}
        end
      end
    end
  end

  describe 'the instance methods' do
    let(:account) {
      FactoryGirl.create  :account,
                          auth_token: auth_token,
                          auth_token_expires_at: auth_token_expires_at
    }

    let(:auth_token) { 'abc123def456' }
    let(:auth_token_expires_at) { 1.day.from_now }

    describe '#ensure_auth_token' do
      subject { account.auth_token }
      before { account.ensure_auth_token }

      context 'when the token is nil' do
        let(:auth_token) { nil }
        it { should_not be_nil }
      end

      context 'when the token is not nil' do
        let(:auth_token) { 'deadbeef' }
        it { should eq('deadbeef') }
      end
    end

    describe '#reset_auth_token' do
      let(:call_the_method) { account.reset_auth_token }
      it_behaves_like 'an auth token resetter'

      describe 'its persistence' do
        subject { account }
        after { call_the_method }
        it { should_not receive(:save) }
      end
    end

    describe '#reset_auth_token!' do
      let(:call_the_method) { account.reset_auth_token! }
      it_behaves_like 'an auth token resetter'

      describe 'its persistence' do
        subject { account }
        after { call_the_method }
        it { should receive(:save) }
      end
    end

    describe '#token_expired?' do
      subject { account.token_expired? }

      context 'when the token expiration is in the future' do
        let(:auth_token_expires_at) { 1.minute.from_now }
        it { should be_falsey }
      end

      context 'when the token expiration is in the past' do
        let(:auth_token_expires_at) { 1.minute.ago }
        it { should be_truthy }
      end
    end

    describe '#password=' do
      let!(:current_password) { account.password.to_s }
      subject { account.password.to_s }

      describe 'before the call' do
        it { should == (current_password) }
      end

      describe 'after the call' do
        before { account.password = 'fudge_knuckles_45' }
        it { should_not eq(current_password) }
      end
    end
  end

  describe 'the class methods' do
    let(:email) { 'foobar@baz.com' }
    let(:token) { 'deadbeef' }
    let(:password) { 'admin4lolz' }
    let(:auth_token_expires_at) { 1.day.from_now }

    let!(:account) {
      FactoryGirl.create  :account,
                          email: email,
                          auth_token: token,
                          password: password,
                          auth_token_expires_at: auth_token_expires_at
    }

    describe '.authenticate_securely' do
      let(:email_param) { email }
      let(:token_param) { token }
      let(:block) { ->(resource) {} }

      subject { Account.authenticate_securely(email_param, token_param, &block) }

      context 'when email is nil' do
        let(:email_param) { nil }
        it { should be_falsey }
      end

      context 'when token is nil' do
        let(:token_param) { nil }
        it { should be_falsey }
      end

      context 'when email and token are provided' do

        context 'when the resource is located' do

          context 'when the auth_token is expired' do
            let(:auth_token_expires_at) { 1.week.ago }

            it 'should reset the account auth_token' do
              allow(Account).to receive(:find_by_email) { account }
              expect(account).to receive(:reset_auth_token!)
              subject
            end

            it { should be_falsey }
          end

          context 'when the auth_token is current' do

            context 'when the auth_token matches' do
              it 'should yield the matched account' do
                expect { |b| Account.authenticate_securely(email_param, token_param, &b) }.to yield_with_args(account)
              end
            end

            context 'when the auth_token does not match' do
              it { should be_falsey }
            end
          end
        end

        context 'when the resource is not located' do
          it { should be_falsey }
        end

      end
    end

    describe '.find_and_authenticate' do
      let(:email_param) { email }
      let(:password_param) { password }

      subject { Account.find_and_authenticate(email_param, password_param) }


      context 'when the resource is located' do

        context 'when the password matches' do
          it { should eq(account) }
        end

        context 'when the password does not match' do
          let(:password_param) { "#{password}_bad" }
          it { should be_falsey }
        end
      end

      context 'when the resource is not located' do
        let(:email_param) { "#{email}_evil" }
        it { should be_falsey }
      end
    end
  end
end