<script>
  import { plugConnection } from "../connexion"
  import { principal } from "../../stores";
  export let message = "Sign in"
  
</script>

<li on:click={() => plugConnection()}>
  <button> {message} </button>
  {#if $principal}
    <span>Logged in as: {$principal.slice(0,5)}...{$principal.slice(-3,4)}</span>
  {/if}
</li>

<style>
  button{
    border-radius: 5px;
    color: #fff;
  }
  span{
    font-size: 10px;
  }
</style>