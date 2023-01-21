import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Config {
  'threshold_fail' : bigint,
  'threshold_pass' : bigint,
  'min_to_propose' : bigint,
  'quadratic_voting' : boolean,
  'min_to_vote' : bigint,
}
export interface ConfigPayload {
  'threshold_fail' : [] | [bigint],
  'threshold_pass' : [] | [bigint],
  'min_to_propose' : [] | [bigint],
  'quadratic_voting' : [] | [boolean],
  'min_to_vote' : [] | [bigint],
}
export interface Proposal {
  'status' : ProposalStatus,
  'votes_no' : bigint,
  'timestamp' : bigint,
  'proposer' : Principal,
  'votes_yes' : bigint,
  'payload' : ProposalPayload,
}
export type ProposalPayload = { 'update_webpage' : { 'message' : string } } |
  { 'update_config' : ConfigPayload };
export type ProposalStatus = { 'open' : null } |
  { 'executed' : null } |
  { 'failed' : string };
export interface TheDao {
  'get_all_proposals' : ActorMethod<[], Array<[bigint, Proposal]>>,
  'get_config' : ActorMethod<[], Config>,
  'get_proposal' : ActorMethod<[bigint], [] | [[bigint, Proposal]]>,
  'get_token_balance' : ActorMethod<[Principal], bigint>,
  'get_votes_from_principal' : ActorMethod<[Principal], Array<[bigint, Vote]>>,
  'get_votes_from_proposal_id' : ActorMethod<[bigint], Array<[bigint, Vote]>>,
  'submit_proposal' : ActorMethod<
    [ProposalPayload],
    { 'Ok' : [bigint, Proposal] } |
      { 'Err' : string }
  >,
  'vote' : ActorMethod<
    [bigint, boolean],
    { 'Ok' : [bigint, Proposal, string] } |
      { 'Err' : string }
  >,
}
export interface Vote {
  'voter' : Principal,
  'vote' : boolean,
  'timestamp' : bigint,
  'power' : bigint,
}
export interface _SERVICE extends TheDao {}
