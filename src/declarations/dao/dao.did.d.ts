import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Proposal {
  'status' : ProposalStatus,
  'votes_no' : bigint,
  'timestamp' : bigint,
  'proposer' : Principal,
  'votes_yes' : bigint,
  'payload' : ProposalPayload,
}
export type ProposalPayload = { 'update_webpage' : { 'message' : string } } |
  { 'update_config' : null };
export type ProposalStatus = { 'open' : null } |
  { 'executed' : null } |
  { 'failed' : string };
export interface Vote {
  'voter' : Principal,
  'vote' : boolean,
  'timestamp' : bigint,
  'power' : bigint,
}
export interface _SERVICE {
  'get_all_proposals' : ActorMethod<[], Array<[bigint, Proposal]>>,
  'get_proposal' : ActorMethod<[bigint], [] | [[bigint, Proposal]]>,
  'get_votes_from_principal' : ActorMethod<[Principal], Array<[bigint, Vote]>>,
  'get_votes_from_proposal_id' : ActorMethod<[bigint], Array<[bigint, Vote]>>,
  'submit_proposal' : ActorMethod<
    [ProposalPayload],
    { 'Ok' : [bigint, Proposal] } |
      { 'Err' : string }
  >,
  'vote' : ActorMethod<
    [bigint, boolean],
    { 'Ok' : [bigint, Proposal] } |
      { 'Err' : string }
  >,
}
