<script>
  import { daoActor, principal } from "../stores"
  import { get } from "svelte/store"
  import mot from "../assets/mot.png"

  let title = ""
  let description = ""
  let type = "update_webpage"
  let webpage = {
    message: ""
  }
  let config = {
    'threshold_fail' : {title: "Fail Threshold", change: false, value: 1},
    'threshold_pass' : {title: "Pass Threshold", change: false, value: 1},
    'proposal_length' :{title: "Proposal Length (s)", change: false, value: 2592000},
    'min_to_propose' : {title: "Minimum MB to propose", change: false, value: 1},
    'min_to_vote' : {title: "Minimum MB to vote", change: false, value: 1},
    'quadratic_voting' : {title: "Quadratic Voting", change: false, value: false},
  }
  export let submitting = false
  let summary

  async function create_proposal(summarypayload) {
    submitting = true
    let dao = get(daoActor)
    if (!dao) {
      return
    }
    let res = await dao.submit_proposal(summarypayload, title, description)
    if (res.Ok) {
      return res.Ok
    } else {
      throw new Error(res.Err)
    }
    submitting = false
  }

  let promise = null

  function handleCreateClick() {

    let summary = null; 

    if(type == "update_webpage" ) {
      summary = {update_webpage: {message: webpage.message}}
    } else {
      summary = {update_config: {}}
      for (const key in config) {
        if(config[key].change){
          summary.update_config[key] = (key != 'quadratic_voting') ? [BigInt(config[key].value)] : [config[key].value];
          continue
        }
        summary.update_config[key] = []
      }
    }
    promise = create_proposal(summary)
  }
</script>

<div class="votemain">
  {#if $principal}
    <img src={mot} class="bg" alt="logo" />
    <h1 class="slogan">Create a proposal</h1>
    <input
      bind:value={title}
      placeholder="Title"
    />
    <input
      bind:value={description}
      placeholder="Description"
    />
    <select
      bind:value={type}
      >
      <option value="update_webpage">Update Webpage</option>
      <option value="update_config">Update Config</option>
    </select>

    {#if type == "update_webpage"}
      <input
        bind:value={webpage.message}
        placeholder="Webpage message"
      />
    {/if}

    {#if type == "update_config"}
      {#each Object.entries(config) as [key, item]}
        <h4>{item.title}</h4>
        <div class="config">
          {#if item.title == "Quadratic Voting"}
            <label><input type="checkbox" bind:checked={item.value}> Enable</label>
          {:else}
            <input
              type="number" min="1"
              bind:value={item.value}
              placeholder="Webpage message"
            />
          {/if}
          <label><input type="checkbox" bind:checked={item.change}> Update?</label>
        </div>
      {/each}
    {/if}

    <button on:click={handleCreateClick} disabled="{submitting}">Create!</button>
    
    {#if promise}
      {#await promise}
        <p style="color: white">...waiting</p>
      {:then proposal}
        <p style="color: white">Proposal #{proposal[0]} created!</p>
      {:catch error}
        <p style="color: red">{error.message}</p>
      {/await}
    {/if}



  {:else}
    <p class="example-disabled">Connect with a wallet to access this example</p>
  {/if}
</div>

<style>
  input {
    width: 100%;
    padding: 12px 20px;
    margin: 8px 0;
    display: inline-block;
    border: 1px solid #ccc;
    border-radius: 4px;
    box-sizing: border-box;
  }
  select{
    width: 100%;
    padding: 12px 20px;
    margin: 8px 0;
  }

  .bg {
    width: 100%;
    max-width: 150px;
    animation: pulse 3s infinite;
    margin: 0 auto;
    animation: pulse 3s infinite;
  }

  .votemain {
    display: flex;
    flex-direction: column;
    justify-content: center;
    width: 88%;
    max-width: 750px;
    margin: 0 auto
  }

  button {
    background-color: #4caf50;
    border: none;
    color: white;
    padding: 15px 32px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 16px;
    margin: 4px 2px;
    cursor: pointer;
  }
  h4{
    color: #fff;
    margin-bottom: 5px;
  }
  .config{
    display:flex;
    color: #fff;
  }
</style>
