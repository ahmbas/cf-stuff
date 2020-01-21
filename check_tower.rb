request_ids.each do |request_id|
  playbook_status = $evm.vmdb(:miq_request).find_by_id(request_id)    
  statuses << playbook_status.state
end

if (statuses & ["pending", "active"]).any?
  $evm.log("info", "Tower jobs is still running, waiting for 30 secodns...")
  $evm.root['ae_retry_interval'] = '30.seconds'
  $evm.root['ae_result'] = 'retry'

elsif statuses.all? { |x| x == "finished" }
  $evm.log("info", "Tower Jobs finished")
  $evm.root['ae_result'] = 'ok'

else
  $evm.log("info", "Unexpected state")
  $evm.root['ae_result'] = 'error'
end

exit MIQ_OK
