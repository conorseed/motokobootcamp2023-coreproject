export const idlFactory = ({ IDL }) => {
  const ProposalStatus = IDL.Variant({
    'open' : IDL.Null,
    'executed' : IDL.Null,
    'failed' : IDL.Text,
  });
  const ProposalPayload = IDL.Variant({
    'update_webpage' : IDL.Record({ 'message' : IDL.Text }),
    'update_config' : IDL.Null,
  });
  const Proposal = IDL.Record({
    'status' : ProposalStatus,
    'votes_no' : IDL.Nat,
    'timestamp' : IDL.Int,
    'proposer' : IDL.Principal,
    'votes_yes' : IDL.Nat,
    'payload' : ProposalPayload,
  });
  const Vote = IDL.Record({
    'voter' : IDL.Principal,
    'vote' : IDL.Bool,
    'timestamp' : IDL.Int,
    'power' : IDL.Nat,
  });
  return IDL.Service({
    'get_all_proposals' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Nat, Proposal))],
        ['query'],
      ),
    'get_proposal' : IDL.Func(
        [IDL.Nat],
        [IDL.Opt(IDL.Tuple(IDL.Nat, Proposal))],
        ['query'],
      ),
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
            'Ok' : IDL.Tuple(IDL.Nat, Proposal),
            'Err' : IDL.Text,
          }),
        ],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
