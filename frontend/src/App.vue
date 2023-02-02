<template>
  <v-container>
    <v-row>
      <v-col><chart initCode='800000'/></v-col>
      <v-col><chart initCode='01211'/></v-col>
    </v-row>
    <v-row>
      <v-col><chart initCode='00388'/></v-col>
      <v-col><chart initCode='00700'/></v-col>
    </v-row>
  </v-container>
</template>

<script>
import chart from './components/chart.vue'

export default {
  name: 'App',
  components: {
    chart
  }
}
</script>

<style>
body {
  margin: 0;
}
</style>
