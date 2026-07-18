<script setup lang="ts">
import useMyAppConfig from '@/composables/useMyAppConfig'
import dayjs from 'dayjs'

const appConfig = useMyAppConfig()
const { public: publicConfig } = useRuntimeConfig()
</script>

<template>
    <div class="flex flex-row flex-wrap gap-4 items-center text-sm opacity-60">
        <div class="flex flex-row gap-1 opacity-100">
            <NuxtLink :href="publicConfig.customLink" target="_blank" class="text-primary hover:underline">015</NuxtLink>
            {{ appConfig?.version ?? 'dev' }}
        </div>

        <div v-if="appConfig?.build_time">
            {{ `Build at ${dayjs(appConfig?.build_time * 1000).format('YYYY-MM-DD')}` }}
        </div>
        <div>{{ publicConfig.copyright }}</div>
    </div>
</template>
