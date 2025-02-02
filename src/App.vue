<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";
import { ethers } from "ethers";
import { getContract } from "./utils/contract";

dayjs.extend(duration);

const candidates = ref<{ name: string; voteCount: number }[]>([]);
const error = ref("");
const isLoading = ref(false);
const contract = ref<any>(null);
const endTime = ref<number | null>(null);
const countdown = ref<string>("");
const isEnd = ref(false);
const open = ref(false);
const currentChooseIndex = ref(0);
const count = ref("");
const winner = ref<null | string>(null);
let timerInterval: number | null = null;

const openModal = (index: number) => {
  open.value = true;
  currentChooseIndex.value = index;
};

const updateCountdown = async () => {
  if (!endTime.value) return;

  const now = dayjs();
  const remaining = dayjs.duration(endTime.value - now.unix(), "seconds");

  if (remaining.asSeconds() <= 0) {
    countdown.value = "Голосование завершено";
    isEnd.value = true;

    if (timerInterval) clearInterval(timerInterval);

    // Проверяем, было ли уже отправлено пожертвование
    const sentFunds = await contract.value.hasSentFunds();
    if (!sentFunds) {
      try {
        const tx = await contract.value.endVoting();
        await tx.wait();
        console.log("Голосование успешно завершено");
      } catch (e) {
        console.error("Ошибка завершения голосования:", e);
      }
    }
  } else {
    countdown.value = `${remaining.hours().toString().padStart(2, "0")}:${remaining.minutes().toString().padStart(2, "0")}:${remaining.seconds().toString().padStart(2, "0")}`;
  }
};

const subscribeToEvents = async () => {
  if (!contract.value) return;

  contract.value.on("VotingEnded", (win: string) => {
    winner.value = win;
    console.log(win);
  });

  console.log("Подписка на событие VotingEnded активна");
};

const fetchCandidates = async () => {
  try {
    isLoading.value = true;
    contract.value = await getContract();

    const timestamp = await contract.value.endTime();
    endTime.value = Number(timestamp);
    isEnd.value = dayjs().unix() >= endTime.value;

    // Добавляем проверку, было ли уже отправлено пожертвование
    const sentFunds = await contract.value.hasSentFunds();
    if (sentFunds) {
      isEnd.value = true;
    }

    updateCountdown();
    if (!isEnd.value) {
      timerInterval = setInterval(updateCountdown, 1000);
    }

    const candidatesList = await contract.value.getCandidates();
    candidates.value = candidatesList.map((cand: [string, number, string]) => ({
      name: cand[0],
      voteCount: cand[1],
    }));
  } catch (e) {
    error.value = (e as Error).message;
  } finally {
    isLoading.value = false;
  }
};

const sendVote = async () => {
  if (!count.value || isNaN(Number(count.value))) {
    alert("Введите корректную сумму");
    return;
  }

  try {
    const tx = await contract.value.sendVote(currentChooseIndex.value, {
      value: ethers.parseEther(count.value),
    });
    await tx.wait();
    alert("Голос принят!");
    open.value = false;
    fetchCandidates(); // Обновляем список кандидатов
  } catch (e) {
    console.error(e);
    alert("Ошибка при голосовании");
  }
};

onMounted(async () => {
  await fetchCandidates(), subscribeToEvents();
});
onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval);
  if (contract.value) {
    contract.value.removeAllListeners("VotingEnded");
    console.log("Отписка от события VotingEnded");
  }
});
</script>

<template>
  <div v-if="!isLoading">
    <h1>Кандидаты</h1>
    <p v-if="countdown">
      До окончания голосования: <strong>{{ countdown }}</strong>
    </p>
    <p v-if="isEnd" style="color: red">Голосование завершено</p>
    <p v-if="error" style="color: red">{{ error }}</p>

    <ul>
      <li v-for="(candidate, index) in candidates" :key="index">
        {{ candidate.name }} — {{ candidate.voteCount }} голосов
        <button v-if="!isEnd" @click="openModal(index)">Проголосовать</button>
      </li>
    </ul>
  </div>
  <div v-else>Загрузка...</div>

  <Teleport to="body">
    <div v-if="open" class="modal">
      <div class="modal-content">
        <p>Введите сумму для кандидата:</p>
        <input type="text" v-model="count" />
        <div class="modal-buttons">
          <button @click="sendVote">Голосовать</button>
          <button @click="open = false">Закрыть</button>
        </div>
      </div>
    </div>
  </Teleport>
  <Teleport to="body">
    <div v-if="winner" class="modal">
      <div class="modal-content">
        <p>Победитель: {{ winner }}</p>
      </div>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
ul {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: 15px;
  padding: 0;

  li {
    display: flex;
    flex-direction: column;
    border: 1px solid gray;
    border-radius: 10px;
    padding: 10px;
    gap: 10px;
    min-width: 200px;
  }
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;

  .modal-content {
    background: white;
    padding: 20px;
    border-radius: 10px;
    text-align: center;
  }

  .modal-buttons {
    margin-top: 10px;
    display: flex;
    gap: 10px;
    justify-content: center;
  }
}
</style>
