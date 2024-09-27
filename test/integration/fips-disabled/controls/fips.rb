# frozen_string_literal: true

control 'license' do
  impact 0.8
  title 'Verify BIG-IP is licensed but does not include FIPS module'
  describe command('tmsh show sys license') do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/FIPS 140, Virtual Edition/) }
  end
end

control 'sys_db' do
  impact 0.8
  title 'Verify BIG-IP is not running in FIPS-140 compliance mode'
  describe command('tmsh list sys db security.fips140.compliance') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/value "false"/) }
  end
end

control 'tmm' do
  impact 0.8
  title 'Verify FIPS feature was not initialised in tmm'
  describe command('zgrep -i FIPS /var/log/tmm*') do
    its('exit_status') { should be <= 1 }
    its('stdout') { should match(/FIPS 140 Compliance is not licensed/) }
  end
end

control 'secure_log' do
  impact 0.8
  title 'Verify the system integrity check has not reported a failure'
  describe command('zgrep "BIG-IP Integrity Check" /var/log/secure*') do
    its('exit_status') { should_not eq 0 }
    its('stdout') { should be empty }
  end
end
