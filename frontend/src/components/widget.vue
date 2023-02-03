<template>
  <v-container>
    <v-row no-gutters>
      <v-col><router-view initCode='800000'/></v-col>
      <v-col><router-view initCode='01211'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col><router-view initCode='00388'/></v-col>
      <v-col><router-view initCode='00700'/></v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
</script>
