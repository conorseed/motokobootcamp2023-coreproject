<script>
  import logo from ".././assets/camp_logo.png"
  import { genericActor } from "../stores"
  import { get } from "svelte/store"

  async function get_config() {
    let dao = get(genericActor);
    if (!dao) {
      return
    }
    let res = await dao.get_config()
    return res
  }
  let promise =  get_config()


  function titleCase (s){
  return s.replace (/^[-_]*(.)/, (_, c) => c.toUpperCase())       // Initial char (after -/_)
   .replace (/[-_]+(.)/g, (_, c) => ' ' + c.toUpperCase()) // First char after each -/_
  }

  function orderConfig(config){
    return Object.entries(config).sort((a,b) => a[0].localeCompare(b[0]))
  }
</script>

<div>
  <header class="App-header">
    <img src={logo} class="App-logo" alt="logo" />
    <h1 class="slogan"><b>Motoko Bootcamp DAO</b></h1>
    <p>A simple DAO built in Motoko on the 
      <a target="_blank" rel="noreferrer" href="https://internetcomputer.org/">IC</a>.
    </p>
  </header>
  <section>
    <div class="invert">
      <h2>Join the fun</h2>
      <p class="large">This DAO controls the message displayed on this website. The message is 100% certified on chain, and cannot be altered by anyone else other than the Dao.</p>
      <p class="large">
        🔌 Install & setup <a target="_blank" rel="noreferrer" href="https://plugwallet.ooo/">Plug wallet</a><br>
        💸 Grab yourself <a target="_blank" rel="noreferrer" href="https://dpzjy-fyaaa-aaaah-abz7a-cai.ic0.app/">some MB tokens</a>
      </p>
      <b>Helpful Links</b>
      <p>
        🧑‍💻 <a target="_blank" rel="noreferrer" href="https://zrm7a-2yaaa-aaaan-qc2ea-cai.ic0.app/">DAO Message Webpage</a><br>
        🔥 <a target="_blank" rel="noreferrer" href="https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=zwnzu-xaaaa-aaaan-qc2eq-cai">DAO Canister Candid UI</a><br>
        📚 <a target="_blank" rel="noreferrer" href="https://github.com/motoko-bootcamp/motokobootcamp-2023">Learn Motoko</a>
      </p>
    </div>
    <div>
      <h2>Current DAO Config:</h2>
      {#await promise}
        <p>Loading...</p>
      {:then config}
        {#each orderConfig(config) as [k,v]}
          <p><em>{titleCase(k)}:</em> <b>{v}
          {#if k.includes('min')}MB{/if}
          {#if k.includes('threshold')} votes{/if}
          {#if k.includes('length')} secs{/if}
          </b></p>
        {/each}
      {:catch error}
        <p style="color: red">{error.message}</p>
      {/await}
    </div>
  </section>
</div>

<style>
  p, h2{
    color: #fff;
    margin-top: 0;
  }
  section{
    display:grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 2rem;
  }
  section > div{
    border-radius: 1rem;
    padding: 1.5rem;
    border: 1px solid;
    background-color: #262626;
  }
  .invert{
    background-color: #ccc;
  }
  .invert p.large{
    font-size: 1.3rem;
  }
  .invert h2, .invert p{
    color: #333
  }
</style>