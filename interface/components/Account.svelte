<script>
  import Proposal from "./Proposal.svelte"
  import { get } from "svelte/store"
  import { daoActor, principal, tokenActor, daoCanisterId } from "../stores"
    import { Principal } from "@dfinity/principal"

  var accountSave = null;

  async function get_account() {
    let dao = get(daoActor);
    if (!dao) {
      return
    }
    let res = await dao.my_account()
    console.log('account', res)
    accountSave = res
    return res
  }
  let promise =  get_account()
  
  async function doRefresh(){
    promise = get_account();
  }

  /////

  async function transfer_back() {
    let dao = get(daoActor);
    if (!dao) {
      return
    }
    let res = await dao.neuron_withdraw()
    console.log('tb', res)
    return res
  }
  let promisetb =  null
  
  async function doTransferBack(){
    promisetb = transfer_back();
  }

  /////

  async function transfer(){
    let token = get(tokenActor)
    if(!token){return}
    
    let request = 
      {
        to: {owner: Principal.fromText(daoCanisterId), subaccount: [accountSave.Ok[1].subaccount]},
        fee: [BigInt(1000000)], memo: [], from_subaccount: [], created_at_time: [], 
        amount: BigInt(1.01 * 100000000)
      }
      console.log(request)
    let res = await token.icrc1_transfer(request)
    console.log('transfer', res)
    return res
  }
  async function doTransfer(){
    promiseTransfer = transfer()
  }
  let promiseTransfer = null

  /////////

  let balance = null

  async function balanceGet(){
    let token = get(tokenActor)
    if(!token){return}
    
    let request = 
      {owner: Principal.fromText(daoCanisterId), subaccount: [accountSave.Ok[1].subaccount]}
    let res = await token.icrc1_balance_of(request)
    balance = res
    console.log(balance)
    return res
  }
  async function doBalance(){
    promiseBalance = balanceGet()
  }
  let promiseBalance = null
</script>

<div id="account">
      <h1>Account</h1>
{#if $principal}
  {#key promise}
    {#await promise}
      <p>Loading...</p>
    {:then account}
        <p><b>AccountId:</b> {account.Ok[0]}</p>
        <p><b>Subaccount:</b> {account.Ok[1].subaccount}</p>
        <hr>
        <p><b>Subaccount MB Balance:</b> {#if balance !== null}{Number(balance)/100000000}{/if}</p>
        <button on:click={() => doBalance()}>Get balance</button>
        
        
        
        {#await promiseTransfer}
        Loading... 
        {:catch error}
          <p style="color: red">{error.message}</p>
        {/await}
    {:catch error}
      <p style="color: red">{error.message}</p>
    {/await}
  {/key}
{:else}
  <p class="example-disabled">Connect with a wallet to access.</p>
{/if}
</div>

<style>
  button{
    margin-bottom: 1rem;
    color: white;
    border-radius: 5px
  }
  h1 {
    color: white;
    font-weight: 700;
  }

  #account{
    width: 100%;
    color: white
  }
</style>
