# frozen_string_literal: true

control 'license' do
  impact 0.8
  title 'Verify BIG-IP is licensed and includes FIPS module'
  describe command('tmsh show sys license') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/FIPS 140, Virtual Edition/) }
  end
end

control 'sys_db' do
  impact 0.8
  title 'Verify BIG-IP is running in FIPS-140 compliance mode'
  describe command('tmsh list sys db security.fips140.compliance') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/value "true"/) }
  end
end

control 'tmm' do
  impact 0.8
  title 'Verify FIPS feature was initialised in tmm'
  describe command('zgrep -i FIPS /var/log/tmm*') do
    its('exit_status') { should be <= 1 }
    its('stdout') { should match(/FIPS 140 Compliance is licensed/) }
  end
end

control 'secure_log' do
  impact 0.8
  title 'Verify the system integrity check has not reported a failure'
  describe command('zgrep "BIG-IP Integrity Check" /var/log/secure*') do
    its('exit_status') { should be <= 1 }
    its('stdout') { should_not match(/\[\s*FAIL\s*\]/) }
  end
end

control 'sys_eicheck' do
  impact 0.8
  title 'Execute sys-eicheck and verify the output meets expectations'

  # This takes some time; only run the control if FIPS_LONG_TESTS environment variable is set
  only_if('FIPS_LONG_TESTS environment variable is unset.') do
    ENV.include?('FIPS_LONG_TESTS')
  end

  describe command('/usr/libexec/sys-eicheck.py') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/0 critical file\(s\) missing/) }
    its('stdout') { should match(/0 critical file\(s\) modified/) }
    its('stdout') { should match(/Integrity Test Result:\s+\[\s+PASS\s+\]/) }
  end
end
