<script>
  export let post
  export let proposer = ("owner" in post[1].proposer) ? post[1].proposer.owner.toString() : "guest" ;
  export let status = Object.keys(post[1].status)[0];
  export let payload = output_payload(post[1].payload);
  export let created = formatDate(post[1].created);
  export let updated = formatDate(post[1].updated)

  function output_payload(payload){
    let result = '';
    
      if('update_config' in payload){
        payload = payload.update_config;
        result += '<p>Update DAO Configuration to:</p>';
        let config = '';
        for (const key in payload) {
          if (payload[key].length !== 0) {
            config += (!config) ? '<ul>' : '';
            config += `<li>${titleCase(key)}: ${payload[key]}`
          }
        }
        config += (!config) ? '</ul>' : '';
        result += config;
      }

      if('update_webpage' in payload){
        result += `<p>Update Webpage message to: <em>${payload.update_webpage.message}<em></p>`;
      }

    return result;
  }

  function titleCase (s){
  return s.replace (/^[-_]*(.)/, (_, c) => c.toUpperCase())       // Initial char (after -/_)
   .replace (/[-_]+(.)/g, (_, c) => ' ' + c.toUpperCase()) // First char after each -/_
  }

  function formatDate(nanoseconds){
    let date = new Date(parseInt(nanoseconds) / 1000000)
    return new Intl.DateTimeFormat('en-US', {
      dateStyle: "short",
      timeStyle: "short"
    }).format(date)
  }
</script>

<div class="post-preview {status}">
  <div class="top">
    <div class="status">{status}</div>
    <p class="votes">👍 {parseInt(post[1].votes_yes)} 👎 {parseInt(post[1].votes_no)}</p>
  </div>
  
  <h2>#{post[0]}{#if post[1].title}: {post[1].title}{/if}</h2>
  {#if post[1].description}<p><b>Description:</b> {post[1].description}</p>{/if}
  <p><b>Specs:</b></p>
  <div class="specs">{@html payload}</div>
  <p class="meta">Created by {proposer} on {created}. Last updated: {updated}.</p>
</div>

<style>
  .post-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2, p, .specs {
    color: white;
  }

  .top{
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    gap: 2rem;
  }
  .top > *{
    flex: 0 1 auto;
  }
  .votes{
    margin: 0
  }
  .status{
    text-transform: uppercase;
    font-weight: 700;
    letter-spacing: 2px;
    font-size: 12px;
    display: inline-block;
    padding: 4px 8px;
    border-radius: 5px;
    color: rgb(84, 68, 1);
    background-color:rgb(255, 247, 138);
  }
  .failed .status{
    color: rgb(112, 0, 0);
    background-color:rgb(255, 138, 138);
  }
  .passed .status, .executed .status{
    color: rgb(0, 112, 21);
    background-color:rgb(138, 255, 159);
  }
  .expired .status{
    color: rgb(100, 100, 100);
    background-color:rgb(175, 175, 175);
  }

  .meta{
    font-size: 12px;
    font-weight: 700;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid;
    color: rgb(255 255 255 / 0.3);
  }
</style>
