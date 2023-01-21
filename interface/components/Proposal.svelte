<script>
  export let post
  export let proposer = ("owner" in post[1].proposer) ? post[1].proposer.owner.toString() : "guest" ;
</script>

<div class="post-preview">
  <h2>{post[0]}</h2>
  <p>{proposer}</p>
  <p>Change website text to: {post[1].payload}</p>
  <p>
    Yes: {parseInt(post[1].votes_yes)}, No: {parseInt(post[1].votes_no)}
  </p>
</div>

<style>
  .post-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2 {
    color: white;
  }

  p {
    color: white;
  }
</style>
