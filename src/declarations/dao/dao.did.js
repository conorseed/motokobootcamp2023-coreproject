export const idlFactory = ({ IDL }) => {
  const ProposalStatus = IDL.Variant({
    'open' : IDL.Null,
    'executed' : IDL.Null,
    'failed' : IDL.Text,
  });
  const ConfigPayload = IDL.Record({
    'threshold_fail' : IDL.Opt(IDL.Nat),
    'threshold_pass' : IDL.Opt(IDL.Nat),
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
    'votes_no' : IDL.Nat,
    'timestamp' : IDL.Int,
    'proposer' : IDL.Principal,
    'votes_yes' : IDL.Nat,
    'payload' : ProposalPayload,
  });
  const Config = IDL.Record({
    'threshold_fail' : IDL.Nat,
    'threshold_pass' : IDL.Nat,
    'min_to_propose' : IDL.Nat,
    'quadratic_voting' : IDL.Bool,
    'min_to_vote' : IDL.Nat,
  });
  const Vote = IDL.Record({
    'voter' : IDL.Principal,
    'vote' : IDL.Bool,
    'timestamp' : IDL.Int,
    'power' : IDL.Nat,
  });
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
    'submit_proposal' : IDL.Func(
        [ProposalPayload],
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
