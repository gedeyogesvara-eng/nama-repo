package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User merepresentasikan entitas pengguna mobile app Anti-Zombi
type User struct {
	IDUser             uuid.UUID          `gorm:"type:char(36);primaryKey" json:"id_user"`
	NamaPengguna       string             `gorm:"type:varchar(100);not null" json:"nama_pengguna"`
	StatusAvatar       string             `gorm:"type:varchar(50);default:'Zombi Akut'" json:"status_avatar"`
	CreatedAt          time.Time          `gorm:"autoCreateTime" json:"created_at"`
	ScreeningHistories []ScreeningHistory `gorm:"foreignKey:IDUser;references:IDUser;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"screening_histories,omitempty"`
}

func (User) TableName() string {
	return "users"
}

// BeforeCreate hook untuk otomatis generate UUID jika belum ada
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.IDUser == uuid.Nil {
		u.IDUser = uuid.New()
	}
	return
}

// ScreeningHistory merepresentasikan hasil pemeriksaan/skrining burnout
type ScreeningHistory struct {
	IDSkrining      uuid.UUID  `gorm:"type:char(36);primaryKey" json:"id_skrining"`
	IDUser          uuid.UUID  `gorm:"type:char(36);not null;index" json:"id_user"`
	SkorAkustik     float64    `gorm:"type:float;not null" json:"skor_akustik"`
	SkorMotorik     float64    `gorm:"type:float;not null" json:"skor_motorik"`
	SkorSklera      float64    `gorm:"type:float;not null" json:"skor_sklera"`
	KategoriBurnout string     `gorm:"type:varchar(100);not null" json:"kategori_burnout"`
	WaktuTes        time.Time  `gorm:"autoCreateTime" json:"waktu_tes"`
	AIRecipes       []AIRecipe `gorm:"foreignKey:IDSkrining;references:IDSkrining;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"ai_recipes,omitempty"`
}

func (ScreeningHistory) TableName() string {
	return "screening_history"
}

func (s *ScreeningHistory) BeforeCreate(tx *gorm.DB) (err error) {
	if s.IDSkrining == uuid.Nil {
		s.IDSkrining = uuid.New()
	}
	return
}

// AIRecipe merepresentasikan resep tugas intervensi dari Python AI
type AIRecipe struct {
	IDResep         uuid.UUID `gorm:"type:char(36);primaryKey" json:"id_resep"`
	IDSkrining      uuid.UUID `gorm:"type:char(36);not null;index" json:"id_skrining"`
	JenisIntervensi string    `gorm:"type:varchar(100);not null" json:"jenis_intervensi"`
	DeskripsiTugas  string    `gorm:"type:text;not null" json:"deskripsi_tugas"`
	IsCompleted     bool      `gorm:"type:tinyint(1);default:0" json:"is_completed"`
}

func (AIRecipe) TableName() string {
	return "ai_recipes"
}

func (r *AIRecipe) BeforeCreate(tx *gorm.DB) (err error) {
	if r.IDResep == uuid.Nil {
		r.IDResep = uuid.New()
	}
	return
}
