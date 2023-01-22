import { principal } from "../stores"
import { daoActor, genericActor } from "../stores"
import { idlFactory as idlFactoryDAO } from "../../src/declarations/dao/dao.did.js"
import { HttpAgent, Actor } from "@dfinity/agent"

//TODO : Add your mainnet id whenever you have deployed on the IC
const daoCanisterId = "zwnzu-xaaaa-aaaan-qc2eq-cai"
/*process.env.NODE_ENV === "development"
    ? "ryjl3-tyaaa-aaaaa-aaaba-cai"
    : "zwnzu-xaaaa-aaaan-qc2eq-cai"*/
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
    // process.env.NODE_ENV === "development"
    //   ? "http://localhost:8000"
    //   : "https://ic0.app",
  })

  // if (process.env.NODE_ENV === "development") {
  //   agent.fetchRootKey()
  // }

  // const actor = Actor.createActor(idlFactoryDAO, {
  //   agent,
  //   canisterId: daoCanisterId,
  // })

  const actor = await window.ic.plug.createActor({
    canisterId: daoCanisterId,
    interfaceFactory: idlFactoryDAO,
  })
  //console.log("actor new", actor)
  principal.update(() => p)
  daoActor.update(() => actor)
}
