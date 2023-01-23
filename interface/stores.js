import { writable } from "svelte/store"

export const view = writable({
  home: 1,
  view: 2,
  create: 3,
  vote: 4,
  current: 1,
  account: 5,
})

export const proposaltoVote = writable({
  proposalID: "null",
})

export const hasvoted = writable(false)

export const principal = writable(null)
export const daoActor = writable(null)
export const genericActor = writable(null)
export const tokenActor = writable(null)

export const daoCanisterId = "zwnzu-xaaaa-aaaan-qc2eq-cai"
export const tokenCanisterId = "db3eq-6iaaa-aaaah-abz6a-cai"
