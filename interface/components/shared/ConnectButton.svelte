<script>
  import { plugConnection } from "../connexion"
  import { principal } from "../../stores";
  export let message = "Sign in"
  
</script>

<button on:click={() => plugConnection()}> {message} </button>
{#if $principal}
  <span>Logged in as: {$principal}</span>
{/if}

<style>
  button{
    border-radius: 5px;
    color: #fff;
  }
  span{
    font-size: 10px;
  }
</style>