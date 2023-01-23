export const idlFactory = ({ IDL }) => {
  const ProposalStatus = IDL.Variant({
    'expired' : IDL.Null,
    'open' : IDL.Null,
    'executed' : IDL.Null,
    'failed' : IDL.Text,
    'passed' : IDL.Null,
  });
  const ConfigPayload = IDL.Record({
    'threshold_fail' : IDL.Opt(IDL.Nat),
    'threshold_pass' : IDL.Opt(IDL.Nat),
    'proposal_length' : IDL.Opt(IDL.Int),
    'neuron_voting' : IDL.Opt(IDL.Bool),
    'min_to_propose' : IDL.Opt(IDL.Nat),
    'quadratic_voting' : IDL.Opt(IDL.Bool),
    'min_to_vote' : IDL.Opt(IDL.Nat),
  });
  const ProposalPayload = IDL.Variant({
    'update_webpage' : IDL.Record({ 'message' : IDL.Text }),
    'update_config' : ConfigPayload,
  });
  const Proposal = IDL.Record({
    'status' : ProposalStatus,
    'title' : IDL.Text,
    'created' : IDL.Int,
    'votes_no' : IDL.Int,
    'description' : IDL.Text,
    'updated' : IDL.Int,
    'proposer' : IDL.Principal,
    'votes_yes' : IDL.Int,
    'payload' : ProposalPayload,
  });
  const Config = IDL.Record({
    'threshold_fail' : IDL.Nat,
    'threshold_pass' : IDL.Nat,
    'proposal_length' : IDL.Int,
    'neuron_voting' : IDL.Bool,
    'min_to_propose' : IDL.Nat,
    'quadratic_voting' : IDL.Bool,
    'min_to_vote' : IDL.Nat,
  });
  const Vote = IDL.Record({
    'voter' : IDL.Principal,
    'vote' : IDL.Bool,
    'timestamp' : IDL.Int,
    'power' : IDL.Int,
  });
  const Subaccount = IDL.Vec(IDL.Nat8);
  const NeuronStatus = IDL.Variant({
    'locked' : IDL.Null,
    'dissolved' : IDL.Null,
    'dissolving' : IDL.Null,
  });
  const NeuronDissolveDelay = IDL.Record({
    'initiated' : IDL.Int,
    'delay' : IDL.Int,
  });
  const Neuron = IDL.Record({
    'status' : NeuronStatus,
    'dissolve_delay' : NeuronDissolveDelay,
    'created' : IDL.Int,
    'balance' : IDL.Nat,
    'updated' : IDL.Int,
  });
  const AccountPayload = IDL.Record({
    'subaccount' : Subaccount,
    'neurons' : IDL.Vec(IDL.Tuple(IDL.Nat, Neuron)),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const TheDao = IDL.Service({
    'get_all_proposals' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Nat, Proposal))],
        ['query'],
      ),
    'get_config' : IDL.Func([], [Config], ['query']),
    'get_proposal' : IDL.Func(
        [IDL.Nat],
        [IDL.Opt(IDL.Tuple(IDL.Nat, Proposal))],
        ['query'],
      ),
    'get_token_balance' : IDL.Func([IDL.Principal], [IDL.Nat], []),
    'get_votes_from_principal' : IDL.Func(
        [IDL.Principal],
        [IDL.Vec(IDL.Tuple(IDL.Nat, Vote))],
        ['query'],
      ),
    'get_votes_from_proposal_id' : IDL.Func(
        [IDL.Nat],
        [IDL.Vec(IDL.Tuple(IDL.Nat, Vote))],
        ['query'],
      ),
    'get_voting_power' : IDL.Func([IDL.Principal], [IDL.Int], []),
    'my_account' : IDL.Func(
        [],
        [
          IDL.Variant({
            'Ok' : IDL.Tuple(IDL.Principal, AccountPayload),
            'Err' : IDL.Text,
          }),
        ],
        [],
      ),
    'neuron_create' : IDL.Func(
        [IDL.Nat, IDL.Int],
        [IDL.Variant({ 'Ok' : IDL.Tuple(IDL.Nat, Neuron), 'Err' : IDL.Text })],
        [],
      ),
    'neuron_dissolve' : IDL.Func(
        [IDL.Nat],
        [IDL.Variant({ 'Ok' : IDL.Tuple(IDL.Nat, Neuron), 'Err' : IDL.Text })],
        [],
      ),
    'receive_cycles' : IDL.Func([], [Result], []),
    'submit_proposal' : IDL.Func(
        [ProposalPayload, IDL.Text, IDL.Text],
        [
          IDL.Variant({
            'Ok' : IDL.Tuple(IDL.Nat, Proposal),
            'Err' : IDL.Text,
          }),
        ],
        [],
      ),
    'vote' : IDL.Func(
        [IDL.Nat, IDL.Bool],
        [
          IDL.Variant({
            'Ok' : IDL.Tuple(IDL.Nat, Proposal, IDL.Text),
            'Err' : IDL.Text,
          }),
        ],
        [],
      ),
  });
  return TheDao;
};
export const init = ({ IDL }) => { return []; };
