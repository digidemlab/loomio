<script lang="coffee">
export default
  props:
    until: null
    diameter:
      type: Number
      default: 30
</script>

<template lang="pug">
div
  v-layout.page-loading(justify-center v-if="!until")
    v-progress-circular(indeterminate color='amber')
  slot(v-if="until")
</template>
