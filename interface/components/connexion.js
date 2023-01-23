import { principal } from "../stores"
import {
  daoActor,
  genericActor,
  tokenActor,
  daoCanisterId,
  tokenCanisterId,
} from "../stores"
import { idlFactory as idlFactoryDAO } from "../../src/declarations/dao/dao.did.js"
import idlFactoryToken from "../../src/declarations/token/token.did.js"
import { HttpAgent, Actor } from "@dfinity/agent"

var agent = new HttpAgent({
  host: "https://ic0.app",
})
var actor = Actor.createActor(idlFactoryDAO, {
  agent,
  canisterId: daoCanisterId,
})
genericActor.update(() => actor)

// See https://docs.plugwallet.ooo/ for more informations
export async function plugConnection() {
  const result = await window.ic.plug.requestConnect({
    whitelist: [daoCanisterId],
  })
  if (!result) {
    throw new Error("User denied the connection")
  }
  const p = await window.ic.plug.agent.getPrincipal()

  const agent = new HttpAgent({
    host: "https://ic0.app",
  })

  const actor = await window.ic.plug.createActor({
    canisterId: daoCanisterId,
    interfaceFactory: idlFactoryDAO,
  })
  principal.update(() => p)
  daoActor.update(() => actor)

  const tokenActorSetup = await window.ic.plug.createActor({
    canisterId: tokenCanisterId,
    interfaceFactory: idlFactoryToken,
  })

  tokenActor.update(() => tokenActorSetup)
}
