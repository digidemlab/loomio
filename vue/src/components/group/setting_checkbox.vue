<script lang="coffee">
export default
  props:
    group: Object
    setting: String
    translateValues: Object
  computed:
    translateKey: ->
      "group_form.#{_.snakeCase(@setting)}"
</script>

<template lang="pug">
v-checkbox.group-setting-checkbox(v-model="group[setting]" :label="$t(translateKey, translateValues)")
</template>
