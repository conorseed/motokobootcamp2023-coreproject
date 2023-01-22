<script>
  import Proposal from "./Proposal.svelte"
  import { get } from "svelte/store"
  import { genericActor, principal } from "../stores"

  async function get_all_proposals() {
    let dao = get(genericActor);
    if (!dao) {
      return
    }
    let res = await dao.get_all_proposals()
    
    return res.reverse()
  }
  let promise =  get_all_proposals()
  async function doRefresh(){
    promise = get_all_proposals();
  }
</script>
<div id="proposals">
      <h1>Proposals</h1>
{#if $principal}
  {#key promise}
    {#await promise}
      <p>Loading...</p>
    {:then proposals}
        <div><button on:click={() => doRefresh()}>Refresh</button></div>
        <div class="proposals">
          {#each proposals as post}
            <Proposal {post} />
          {/each}
        </div>
    {:catch error}
      <p style="color: red">{error.message}</p>
    {/await}
  {/key}
{:else}
  <p class="example-disabled">Connect with a wallet to access this example</p>
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

  #proposals {
    display: flex;
    flex-direction: column;
  }
  .proposals{
    display:grid;
    grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr));
    gap: 2rem;
  }
</style>
